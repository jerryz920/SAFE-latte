package prolog.builtins
import prolog.terms._
import prolog.io.IO
import prolog.interp.Prog

/*
 * Many builtin operators are realized by the ``is'' builtin (by fluents/Lib.scala)
 */
final class is() extends FunBuiltin("is", 2) {
  def eval(expr: Term): Any = {
    expr match {
      case x: Num => x.getValue
      case t: Fun =>
        {
          val l = t.args.length
          val rs = new Array[Any](l)
          var ok = true
          for (i <- 0 until l) {
            rs(i) = eval(t.getArg(i))
            if (rs(i) == null) ok = false
          }
          if (!ok) null
          else if (2 == l) {
            var x: BigDecimal = null
            var y: BigDecimal = null
            var xx: String = null  // Dealing with strings
            var yy: String = null
            if(rs(0).isInstanceOf[BigDecimal]) {
              x = rs(0).asInstanceOf[BigDecimal]
              y = rs(1).asInstanceOf[BigDecimal]
            } else if(rs(0).isInstanceOf[String]) {
              xx = rs(0).asInstanceOf[String]
              yy = rs(1).asInstanceOf[String]
            } else {
              return null  // types not handled
            }
            t.sym match {
              case "+" => x + y
              case "-" => x - y
              case "*" => x * y
              case "/" => x / y
              case "//" => BigDecimal(x.toBigInt / y.toBigInt)
              case "div" => BigDecimal(x.toBigInt / y.toBigInt)
              case "mod" => BigDecimal(x.toBigInt.mod(y.toBigInt))
              // case "?" => if (x < y) -1 else if (x == y) 0 else 1
              // Generalize as below this to deal with strings
              case "?" =>
                var cmp = 0
                if(xx != null && yy != null) {  // strings
                  cmp = xx.compare(yy)
                } else if (x != null && y != null) { // decimals
                  cmp = x.compare(y)
                }
                if(cmp < 0) -1
                else if(cmp == 0) 0
                else 1
              case "pow" => x.pow(y.toInt)
              case "^" => x.pow(y.toInt)
              case "log" => BigDecimal(math.log(x.doubleValue()) / math.log(y.doubleValue()))
              case "<<" => BigDecimal(x.toBigInt << y.toInt)
              case ">>" => BigDecimal(x.toBigInt >> y.toInt)
              case "xor" => BigDecimal(x.toBigInt ^ y.toInt)
              case """/\""" => BigDecimal(x.toBigInt & y.toInt)
              case """\/""" => BigDecimal(x.toBigInt | y.toInt)
              case "gcd" => BigDecimal(x.toBigInt gcd y.toInt)
              case "getbit" => if (x.toBigInt.testBit(y.toInt)) 1 else 0
              case _ => null
            }
          } else if (1 == l) {
            val x = rs(0).asInstanceOf[BigDecimal]
            t.sym match {
              case "abs" => x.abs
              case "floor" => BigDecimal(x.toBigInt)
              case "ceiling" => BigDecimal(x.toBigInt + 1)
              case "lsb" => BigDecimal(x.toBigInt.lowestSetBit)
              case "bitcount" => BigDecimal(x.toBigInt.bitCount)
              case "random" => BigDecimal(x.toBigInt.bitCount)
              case _ => null
            }
          } else if (3 == l) {
            val x = rs(0).asInstanceOf[BigDecimal]
            val y = rs(1).asInstanceOf[BigDecimal]
            val z = rs(2).asInstanceOf[BigDecimal]
            t.sym match {
              case "setbit" => {
                val n = x.toBigInt
                BigDecimal(
                  if (0 == z.toInt) n.clearBit(y.toInt) else n.setBit(y.toInt))
              }
              case _ => null
            }

          } else null
        }
      case c: Const => c.sym match {
        case "random" => math.random
        case "pi" => math.Pi
        case "e" => math.E
        case _ => c.sym
      }
      case _: Term => null
    }
  }

  override def exec(p: Prog) = {
    val e = eval(getArg(1))
    var r: BigDecimal = null
    if (e.isInstanceOf[BigDecimal]) r = e.asInstanceOf[BigDecimal]
    else if (e.isInstanceOf[Integer]) r = BigDecimal(e.asInstanceOf[Integer])
    if (null == r || e == null) IO.errmes("bad arithmetic operation", this, p)
    else putArg(0, Real(r), p)
  }

  override def safeCopy() = {
    new is()
  }

}
