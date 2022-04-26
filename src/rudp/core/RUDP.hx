package rudp.core;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import openfl.Lib;
import openfl.errors.Error;
import openfl.events.DatagramSocketDataEvent;
import openfl.events.Event;
import openfl.net.DatagramSocket;
import openfl.utils.ByteArray;
import openfl.utils.Function;
import openfl.utils.Object;
import rudp.utils.SUInt;
import rudp.events.RUDPEvent;
import rudp.events.RUDPErrorEvent;
/**
 * ...
 * @author Christopher Speciale
 */
@:access(rudp.core.Connection)
class RUDP
{

	public static inline var PROTOCOL_VERSION:Int = 1;

	public var localAddress:Null<String>;
	public var localPort:Null<Int>;

	public var onData(get, set):(ByteArray, Connection)->Void;
	public var onConnect(get, set):RUDPEvent->Void;
	public var onClose(get, set):RUDPEvent->Void;
	public var onError(get, set):RUDPErrorEvent->Void;

	public var receiving(get, null):Bool;

	private var _udpSocket:DatagramSocket;

	private var _onData:(ByteArray, Connection)->Void;
	private var _onConnect:RUDPEvent->Void;
	private var _onClose:RUDPEvent->Void;
	private var _onError:RUDPErrorEvent->Void;

	private var _receiving:Bool = false;


	private var _connectionMap:StringMap<Connection>;
	
	private function get_onError():RUDPErrorEvent->Void
	{
		return _onError;
	}
	
	private function set_onError(value:RUDPErrorEvent->Void):RUDPErrorEvent->Void
	{
		if (onError != null){		
		_udpSocket.removeEventListener(RUDPErrorEvent.ERROR, _onError);		
		
		}
		_udpSocket.addEventListener(RUDPErrorEvent.ERROR, value);
		return _onError = value;
	}
	
	private function get_onData():(ByteArray, Connection)->Void
	{
		return _onData;
	}

	private function set_onData(value:(ByteArray, Connection)->Void):(ByteArray, Connection)->Void
	{

		return _onData = value;
	}

	private function get_onConnect():RUDPEvent->Void
	{
		return _onConnect;
	}

	private function set_onConnect(value:RUDPEvent->Void):RUDPEvent->Void
	{
		if (_onConnect != null){
			_udpSocket.removeEventListener(RUDPEvent.CONNECT, _onConnect);
			
		}
		_udpSocket.addEventListener(RUDPEvent.CONNECT, value);
		
		return _onConnect = value;
	}

	private function get_onClose():RUDPEvent->Void
	{
		return _onClose;
	}

	private function set_onClose(value:RUDPEvent->Void):RUDPEvent->Void
	{
		if (_onClose != null){
			_udpSocket.removeEventListener(RUDPEvent.CLOSE, _onClose);
			
		}
		_udpSocket.addEventListener(RUDPEvent.CLOSE, value);
		return _onClose = value;
	}

	private function get_receiving():Bool
	{
		return _receiving;
	}

	public function new(?localAddress:String, ?localPort:Int)
	{
		this.localAddress = localAddress;
		this.localPort = localPort;
	}

	public function connect(remoteAddress:String, remotePort:Null<Int>):Void
	{
		if (_receiving == false) throw new Error("RUDP instance must be started before attempting a connection");
		//if(ip!= null && port != null) _udpSocket.connect(ip, port);

		//this.onConnect = onConnect;

		var connection:Connection =  Connection._getConnection(remoteAddress, remotePort, this);
		_connectionMap.set(connection.hash, connection);

	}

	public function start(onData:(ByteArray, Connection)->Void, onConnect:RUDPEvent->Void, onClose:RUDPEvent->Void, onError:RUDPErrorEvent->Void = null, connectionType:ConnectionType = CLIENT):Void
	{

		_udpSocket = new DatagramSocket();
		_connectionMap = new StringMap();

		_onData = onData;
		_onConnect = onConnect;
		_onClose = onClose;

		_udpSocket.addEventListener(DatagramSocketDataEvent.DATA, _getData);
		_udpSocket.addEventListener(RUDPEvent.CONNECT, onConnect);
		_udpSocket.addEventListener(RUDPEvent.CLOSE, onClose);
		if (onError != null){
			_udpSocket.addEventListener(RUDPErrorEvent.ERROR, onError);
		}
		Lib.application.window.application.onExit.add(_close);

		_udpSocket.receive();
		_receiving = true;
		if (connectionType == SERVER)
		{
			if (localAddress != null && localPort != null)
			{
				_udpSocket.bind(localPort, localAddress);
			}
		}
	}

	public function close():Void
	{
		_close();
		_udpSocket.close();			
		_receiving = false;
		
		_clean();
	}
	
	private function _close(e:Int = 0):Void{
		for (connection in _connectionMap){
			connection.close();
		}		
		
	}	

	private function _clean():Void{
		_connectionMap.clear();
		_onClose = null;
		_onData = null;
		_onConnect = null;
	}

	private function _getData(e:DatagramSocketDataEvent):Void
	{
		//trace("incoming data");
		var data:ByteArray = e.data;
		var dataObject:Object = {};

		var resend:Bool = data.readBoolean();

		var protocolVer:Int = data.readUnsignedShort();
		data.position = 9;

		var frameType:FrameType = data.readUnsignedShort();
		data.position = 17;

		var sequence:SUInt = data.readUnsignedInt();
		data.position = 49;

		var length:UInt = data.readUnsignedShort();
		data.position = 65;

		//trace("Got Data", data.length, protocolVer, frameType, length, length > 0 ? data.readUTF() : "");
		var connection:Connection = null;

		switch (frameType)
		{
			case PACKET:
				connection = getConnection(e.srcAddress, e.srcPort);
				if (connection != null)
				{
					_sendAck(connection, sequence);
					if (connection._inSequence == sequence)
					{
						_onData(data, connection);
						connection._inSequence++;
						//if (resend)
						//	{
						connection._tryNextFrame();
						//}

					}
					else if (connection._inSequence < sequence)
					{

						connection._inFrameCache.set(sequence, data);

					}
					//else
					//{
						//	trace(sequence,connection._inSequence, resend);
					//}
				}
			case CONNECT:
				if (protocolVer == PROTOCOL_VERSION)
				{
					connection = getConnection(e.srcAddress, e.srcPort);
					if (connection != null){
						return;
					}
					connection = Connection._getConnection(e.srcAddress, e.srcPort, this, true);
					_connectionMap.set(connection.hash, connection);
				}			
			case HANDSHAKE:
				connection = getConnection(e.srcAddress, e.srcPort);
				if (connection != null)
				{
					connection._onHandshake();
					connection._inSequence = sequence;
				}
			case ACK:
				connection = getConnection(e.srcAddress, e.srcPort);
				if(connection != null)	connection._acceptAck(sequence);
			case FIN:
				connection = getConnection(e.srcAddress, e.srcPort);
				if (connection != null) connection._close();
				
		}

	}

	private function _sendAck(connection:Connection, sequence:SUInt)
	{
		
		connection._sendAck(sequence);
	}

	public function getConnection(ip:String, port:Int):Connection
	{
		return _connectionMap.get('$ip:$port');
	}

}