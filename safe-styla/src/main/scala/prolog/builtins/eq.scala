package prolog.builtins
import prolog.terms._
import prolog.interp.Prog

final class eq() extends FunBuiltin("eq", 2) {
  def as(x: Term, y: Term) = {
    args = Array(x, y)
    this
  }

  override def exec(p: Prog) = {
    putArg(1, getArg(0), p)
  }

  override def toString = {
    if(args == null || args.length == 0)  "="
    else getArg(0) + "=" + getArg(1)
  }

  override def safeCopy() = {
    new eq()
  }

}
