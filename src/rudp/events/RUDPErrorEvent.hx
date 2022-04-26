package rudp.events;
import rudp.error.RUDPError;
import rudp.core.Connection;
/**
 * ...
 * @author Christopher Speciale
 */
class RUDPErrorEvent extends RUDPEvent
{
	public static inline var ERROR:String = "error";
	public var errorMessage(default, null):String;
	public var error(default, null):RUDPError;
	public function new(type:String, bubbles:Bool=false, cancelable:Bool=false, error:RUDPError, errorMessage:String = "", ?connection:Connection) 
	{
		super(type, bubbles, cancelable, connection);
		this.error = error;
		this.errorMessage = errorMessage;
		
	}
	override public function clone():RUDPErrorEvent 
	{
		return new RUDPErrorEvent(type, bubbles, cancelable, error, errorMessage, connection);
	}
	
}
