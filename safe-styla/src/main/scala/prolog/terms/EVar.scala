package prolog.terms

final class EVar(name: String) extends Var(name) {

  override def tcopy(dict: Copier): Term = {
    val root = ref
    //println(s"[terms.EVar tcopy] dict=${dict};  this=${this};   root=${root}")
    if (root == this) { 
      dict.getOrElseUpdate(this, new EVar(name))
      //println(s"[terms.EVar tcopy] dict=${dict}")
      //dict(this)
    } else root.tcopy(dict)  // Reduce distinct variables when multiple variables are bound to the same thing 
  }


  override def toString = {
    if (unbound) {
      val h: Long = hashCode
      val n: Long = if (h < 0) 2 * (-h) + 1 else 2 * h
      //"~_" + n
      "$_" + n
    } else ref.toString
  }

  override def hashCode = {
    if(unbound) {
      //super.objectHashCode // Env vars are different 
      name.hashCode     // to distinguish difference env vars
    } else ref.hashCode
  }
   
}
