package prolog
package proof

import prolog.interp.Unfolder
import prolog.terms.Term

/**
 * ProofStep contains the proof info of an inference step based on Unfolder.
 * The state kept in a ProofStep instance is subsumed by its corresponding
 * unfolder instance. 
 */
class ProofStep(val goal: List[Term], val oldtop: Int, val previousClause: List[Term]) {

  def safeCopy(): ProofStep = {
    ProofStep( LogicEngine.copyList(goal), oldtop, LogicEngine.copyList(previousClause) )
  }

  def getOldtop(): Int = {
    oldtop
  }
}

object ProofStep {

  def apply(goal: List[Term], oldtop: Int, previousClause: List[Term]): ProofStep = 
      new ProofStep(goal, oldtop, previousClause)
 
  def apply(unfolder: Unfolder): ProofStep = new ProofStep(unfolder.goal, unfolder.getOldtop, unfolder.previousClause)

}

