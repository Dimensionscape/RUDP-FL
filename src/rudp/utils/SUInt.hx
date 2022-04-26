package rudp.utils;

/**
 * ...
 * @author Christopher Speciale
 */
@:transitive
abstract SUInt(Int) to Int from Int
{
	public static inline var MAX_UINT_32:UInt = MAX_INT_32 + MAX_INT_32 + 1;
	public static inline var MAX_INT_32:Int = 2147483647;
	public static inline var ABS_MIN_INT_32:UInt = MAX_INT_32 + 1;
	
	@:op(A + B) private static inline function add(a:SUInt, b:SUInt):SUInt {
		return a.toInt() + b.toInt();
	}

	@:op(A / B) private static inline function div(a:SUInt, b:SUInt):Float {
		return a.toFloat() / b.toFloat();
	}

	@:op(A * B) private static inline function mul(a:SUInt, b:SUInt):SUInt {
		return a.toInt() * b.toInt();
	}

	@:op(A - B) private static inline function sub(a:SUInt, b:SUInt):SUInt {
		return a.toInt() - b.toInt();
	}

	@:op(A > B)
	private static #if !js inline #end function gt(a:SUInt, b:SUInt):Bool {

		var i1:UInt = a;
		var i2:UInt = b;
		var distance:UInt = 0;

		if ((i1 < i2 && (distance = i2 - i1) > ABS_MIN_INT_32) ||
		(i1 > i2 && (distance = i1 - i2) < ABS_MIN_INT_32))
		{
			return true;
		}
		if (distance == ABS_MIN_INT_32)
		{
			return i1 > i2;
		}
		return false;
	
	}

	@:op(A >= B)
	private static #if !js inline #end function gte(a:SUInt, b:SUInt):Bool {
			var aNeg = a.toInt() < 0;
			var bNeg = b.toInt() < 0;
			return if (aNeg != bNeg) aNeg; else a.toInt() >= b.toInt();
			}

			@:op(A < B) private static inline function lt(a:SUInt, b:SUInt):Bool
			{
				return gt(b, a);
			}

	@:op(A <= B) private static inline function lte(a:SUInt, b:SUInt):Bool
	{
		return gte(b, a);
	}

	@:op(A & B) private static inline function and(a:SUInt, b:SUInt):SUInt
	{
		return a.toInt() & b.toInt();
	}

	@:op(A | B) private static inline function or(a:SUInt, b:SUInt):SUInt
	{
		return a.toInt() | b.toInt();
	}

	@:op(A ^ B) private static inline function xor(a:SUInt, b:SUInt):SUInt
	{
		return a.toInt() ^ b.toInt();
	}

	@:op(A << B) private static inline function shl(a:SUInt, b:Int):SUInt
	{
		return a.toInt() << b;
	}

	@:op(A >> B) private static inline function shr(a:SUInt, b:Int):SUInt
	{
		return a.toInt() >>> b;
	}

	@:op(A >>> B) private static inline function ushr(a:SUInt, b:Int):SUInt
	{
		return a.toInt() >>> b;
	}

	@:op(A % B) private static inline function mod(a:SUInt, b:SUInt):SUInt
	{
		return Std.int(a.toFloat() % b.toFloat());
	}

	@:commutative @:op(A + B) private static inline function addWithFloat(a:SUInt, b:Float):Float
	{
		return a.toFloat() + b;
	}

	@:commutative @:op(A * B) private static inline function mulWithFloat(a:SUInt, b:Float):Float
	{
		return a.toFloat() * b;
	}

	@:op(A / B) private static inline function divFloat(a:SUInt, b:Float):Float
	{
		return a.toFloat() / b;
	}

	@:op(A / B) private static inline function floatDiv(a:Float, b:SUInt):Float
	{
		return a / b.toFloat();
	}

	@:op(A - B) private static inline function subFloat(a:SUInt, b:Float):Float
	{
		return a.toFloat() - b;
	}

	@:op(A - B) private static inline function floatSub(a:Float, b:SUInt):Float
	{
		return a - b.toFloat();
	}

	@:op(A > B) private static inline function gtFloat(a:SUInt, b:Float):Bool
	{
		return a.toFloat() > b;
	}

	@:commutative @:op(A == B) private static inline function equalsInt<T:Int>(a:SUInt, b:T):Bool
	{
		return a.toInt() == b;
	}

	@:commutative @:op(A != B) private static inline function notEqualsInt<T:Int>(a:SUInt, b:T):Bool
	{
		return a.toInt() != b;
	}

	@:commutative @:op(A == B) private static inline function equalsFloat<T:Float>(a:SUInt, b:T):Bool
	{
		return a.toFloat() == b;
	}

	@:commutative @:op(A != B) private static inline function notEqualsFloat<T:Float>(a:SUInt, b:T):Bool
	{
		return a.toFloat() != b;
	}

	@:op(A >= B) private static inline function gteFloat(a:SUInt, b:Float):Bool
	{
		return a.toFloat() >= b;
	}

	@:op(A > B) private static inline function floatGt(a:Float, b:SUInt):Bool
	{
		return a > b.toFloat();
	}

	@:op(A >= B) private static inline function floatGte(a:Float, b:SUInt):Bool
	{
		return a >= b.toFloat();
	}

	@:op(A < B) private static inline function ltFloat(a:SUInt, b:Float):Bool
	{
		return a.toFloat() < b;
	}

	@:op(A <= B) private static inline function lteFloat(a:SUInt, b:Float):Bool
	{
		return a.toFloat() <= b;
	}

	@:op(A < B) private static inline function floatLt(a:Float, b:SUInt):Bool
	{
		return a < b.toFloat();
	}

	@:op(A <= B) private static inline function floatLte(a:Float, b:SUInt):Bool
	{
		return a <= b.toFloat();
	}

	@:op(A % B) private static inline function modFloat(a:SUInt, b:Float):Float
	{
		return a.toFloat() % b;
	}

	@:op(A % B) private static inline function floatMod(a:Float, b:SUInt):Float
	{
		return a % b.toFloat();
	}

	@:op(~A) private inline function negBits():SUInt
	{
		return ~this;
	}

	@:op(++A) private inline function prefixIncrement():SUInt
	{
		return ++this;
	}

	@:op(A++) private inline function postfixIncrement():SUInt
	{
		return this++;
	}

	@:op(--A) private inline function prefixDecrement():SUInt
	{
		return --this;
	}

	@:op(A--) private inline function postfixDecrement():SUInt
	{
		return this--;
	}

	private inline function toString(?radix:Int):String
	{
		return Std.string(toFloat());
	}

	private inline function toInt():Int
	{
		return this;
	}

	@:to private #if (!js || analyzer) inline #end function toFloat():Float {
			var int = toInt();
			if (int < 0)
	{
		return 4294967296.0 + int;
	}
	else
	{
		return int + 0.0;
	}
}
}