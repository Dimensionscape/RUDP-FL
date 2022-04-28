package rudp.core;
import haxe.Timer;
import haxe.ds.IntMap;
import haxe.io.Bytes;
import openfl.Lib;
import openfl.errors.Error;
import openfl.events.Event;
import openfl.net.DatagramSocket;
import openfl.utils.ByteArray;
import rudp.core.RUDP;
import rudp.error.RUDPError;
import rudp.events.RUDPErrorEvent;
import rudp.events.RUDPEvent;
import rudp.utils.SUInt;

/**
 * ...
 * @author Christopher Speciale
 */
class Connection
{
	private static inline var KEEP_ALIVE:Int = 75000;
	private static inline var DELIVERY_WINDOW:Int = 500;
	private static inline var CONNECTION_ATTEMPT_DELTA:Int = 3000;
	private static inline var MAX_DATA_SIZE = 4096;
	
	public var ip(get, null):String;
	public var port(get, null):Int;
	public var hash(default, null):String;
	public var connected(get, null):Bool;
	public var isIncoming(get, null):Bool;
	
	public var timeout:UInt = 20000;
	
	private var _timeoutID:UInt;
	private var _timeoutTimer:Timer;	
	private var _isIncoming:Bool;
	private var _ip:String;
	private var _port:Int;
	private var _rudp:RUDP;
	private var _connected:Bool = false;
	private var _alive:Bool = false;

	private var _inFrameCache:IntMap<ByteArray>;
	private var _outFrameCache:IntMap<ByteArray>;
	private var _outFrameTimerCache:IntMap<Int>;
	private var _outgoingQue:Array<ByteArray>;

	private var _inSequence:SUInt = 0;
	private var _outSequence:SUInt = 0;
	private var _ackPosition:UInt = 0;
	
	private var _deliverWindowExceeded:Bool = false;
	
	private var _writeBuffer:ByteArray;	
	
	private function get_isIncoming():Bool{
		return _isIncoming;
	}
	private function get_connected():Bool
	{
		return _connected;
	}

	private function get_ip():String
	{
		return _ip;
	}

	private function get_port():Int
	{
		return _port;
	}
	private function new(ip:String, port:Int, rudp:RUDP, isIncoming:Bool)
	{
		_ip = ip;
		_port = port;
		_rudp = rudp;
		_isIncoming = isIncoming;
		_writeBuffer = new ByteArray();
		
		hash = '$ip:$port';

		_inFrameCache = new IntMap();
		_outFrameCache = new IntMap();
		_outFrameTimerCache = new IntMap();
		_outgoingQue = new Array();
		_randomizeSequence();
		_handleConnection();

	}

	public function send(data:ByteArray):Void
	{
		if(_connected){
		_send(data);
		} else {
			_dispatchError(RUDPError.IO_ERROR, "Cannot continue operation on an invalid connection");
		}
	}
	
	public function close():Void{
		_send(null, FIN, false);
		_onClose();
	}
	
	private function _close():Void{
		_onClose();
		@:privateAccess _rudp._udpSocket.dispatchEvent(new RUDPEvent(RUDPEvent.CLOSE, false, false, this));
		
	}
	
	private function _onClose():Void{
		@:privateAccess _rudp._connectionMap.remove(hash);
		_clean();
	}
	
	private function _clean():Void{
		for (id in _outFrameTimerCache){
			Lib.clearInterval(id);
		}
		if (connected) Lib.clearInterval(_timeoutID);
		else _stopConnectionAttempt();
		_inFrameCache.clear();
		_outFrameCache.clear();
		_outFrameTimerCache.clear();
		_outgoingQue.resize(0);
		
		_connected = false;
	}
	
	private function _randomizeSequence():Void{
		_outSequence = _ackPosition = Math.round(Math.random() * SUInt.MAX_UINT_32);
	}
	
	private function _dispatchError(error:RUDPError, errorMessage:String):Void{
		@:privateAccess _rudp._udpSocket.dispatchEvent(new RUDPErrorEvent(RUDPErrorEvent.ERROR, false, false, error, errorMessage, this));
	}

	private function _handleConnection():Void
	{
		_timeoutTimer = new Timer(CONNECTION_ATTEMPT_DELTA);
		_timeoutTimer.run = _connectionAttempt;
		
		_timeoutID = Lib.setTimeout(_onConnectionFailed, timeout);
		_connectionAttempt();
	}
	
	private function _connectionAttempt():Void{
		_send(null, _isIncoming? HANDSHAKE : CONNECT);		
	}
	
	private function _onConnectionFailed():Void{
		_onClose();
		if (!_isIncoming) _dispatchError(CONNECTION_ERROR, "Remote connection attempt has timed out and the connection could not be completed");
		
	}
	
	private function _stopConnectionAttempt():Void{
		_timeoutTimer.run = null;
		_timeoutTimer.stop();		
		Lib.clearTimeout(_timeoutID);
	}

	private function _send(data:ByteArray, frameType:FrameType = PACKET, resend:Bool = false):Void
	{
		//TODO: Reduce header to 56 bits as shown
		//|````````|```````````````|```````````````|````````|````````````````````````````````````````|``````````````````````````````|
		//| 1 bit  |   3 bits      |   3 bits      |  1 bit |                 32 bits                |           16 bits            |
		//|_resend_|_protocol_ver__|__frame_type___|________|________________sequence________________|_________data_length__________|
		//|                                                                                                                         |
		//|                                                                                                                         |
		//|                                                                                                                         |
		//|                                                                                                                         |
		//|                                                      0 - 4096 bytes                                                     |
		//|                                                                                                                         |
		//|                                                                                                                         |
		//|                                                                                                                         |
		//|                                                                                                                         |
		//|                                                                                                                         |
		//|______________________________________________________packet_data________________________________________________________|
		
		
		var frame:ByteArray = null;
		if (!resend)
		{
			frame = new ByteArray();
			frame.writeBoolean(resend);
			frame.writeUnsignedInt(RUDP.PROTOCOL_VERSION);
			frame.position = 9;
			frame.writeUnsignedInt(frameType);
			if(!_deliverWindowExceeded){
				frame.position = 17;
				frame.writeUnsignedInt(_outSequence);
			}
			frame.position = 49;
			if (frameType == PACKET)
			{
				if (data != null)
				{
					data.position = 0;
					if (data.length > MAX_DATA_SIZE){
						_splitFrames(data);
						return;
					}
					frame.writeUnsignedInt(data.length);
					frame.position = 65;
					frame.writeBytes(data);
				}
				else
				{
					frame.writeUnsignedInt(0);
				}

				if ((_deliverWindowExceeded = _outSequence - _ackPosition > DELIVERY_WINDOW)){
					_outgoingQue.push(frame);
					return;
				}
		
				_outFrameCache.set(_outSequence, frame);

				_outFrameTimerCache.set(_outSequence, Lib.setInterval(_retransmitFrame, 3000, [(_outSequence:UInt)]));
				_outSequence++;				

			} else {
				frame.writeUnsignedInt(0);
			}
			frame.position = 0;
		}
		else {
			frame = data;
		}		
			
		@:privateAccess _rudp._udpSocket.send(frame, 0, frame.length, ip, port);	
		
	}
	
	private function _splitFrames(data:ByteArray):Void{
		
		while (data.position != data.length){
			var bytesRemaining:Int = data.length - data.position;
			var bytesAvailable:Int = bytesRemaining > MAX_DATA_SIZE ? MAX_DATA_SIZE : bytesRemaining;
			data.readBytes(_writeBuffer, 0, bytesAvailable);
			send(_writeBuffer);
			//trace(_writeBuffer.readUTF());
		}
			
			_writeBuffer.clear();	
	}
	
	private function _sendAck(sequence:SUInt):Void{
		_alive = true;
		
		var frame:ByteArray = new ByteArray();
			frame.writeBoolean(false);
			frame.writeUnsignedInt(RUDP.PROTOCOL_VERSION);
			frame.position = 9;
			frame.writeUnsignedInt(FrameType.ACK);
			frame.position = 17;
			frame.writeUnsignedInt(sequence);
			frame.position = 49;
			frame.writeUnsignedInt(0);
			frame.position = 0;
			
			@:privateAccess _rudp._udpSocket.send(frame, 0, frame.length, ip, port);
	}

	private function _retransmitFrame(sequence:SUInt):Void
	{
		_send(_outFrameCache.get(sequence), PACKET, true);
		
	}

	private function _acceptAck(sequence:SUInt):Void
	{
		_outFrameCache.remove(sequence);
		Lib.clearInterval(_outFrameTimerCache.get(sequence));
		_outFrameTimerCache.remove(sequence);
		_ackPosition++;
		
		if (_outgoingQue.length > 0){
			var frame:ByteArray = _outgoingQue.shift();
				frame.position = 17;
				frame.writeUnsignedInt(_outSequence);
				frame.position = 0;
				
				_outFrameCache.set(_outSequence, frame);

				_outFrameTimerCache.set(_outSequence, Lib.setInterval(_retransmitFrame, 3000, [(_outSequence:UInt)]));
				_outSequence++;		
				@:privateAccess _rudp._udpSocket.send(frame, 0, frame.length, ip, port);
				
		} else {
			_deliverWindowExceeded = false;
		}
		
		
	}
	private function _onHandshake():Void
	{
		//_ackPosition++;
		if (!_isIncoming)
		{
			_send(null, HANDSHAKE);
		}
		_connected = true;
		
		_stopConnectionAttempt();
		_setKeepAlive();

		var event:RUDPEvent = new RUDPEvent(RUDPEvent.CONNECT, false, false, this);
		var udpSocket:DatagramSocket = @:privateAccess _rudp._udpSocket;

		udpSocket.dispatchEvent(event);

	}
	
	private function _setKeepAlive():Void{
		_timeoutID = Lib.setInterval(_onKeepAlive, KEEP_ALIVE);
	}
	
	private function _onKeepAlive():Void{
		if (!_alive){
			_close();	
		}
		_alive = false;
	}
	
	private function _tryNextFrame():Void
	{
		while (_inFrameCache.exists(_inSequence))
		{
			_rudp.onData(_inFrameCache.get(_inSequence), this);
			_inFrameCache.remove(_inSequence);
			_inSequence++;
		}
	}
	private static function _getConnection(ip:String, port:Int, rudp:RUDP, isIncoming:Bool = false ):Connection
	{
		return new Connection(ip, port, rudp, isIncoming);
	}
}
