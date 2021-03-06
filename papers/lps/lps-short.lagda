
\documentclass[a4paper,english]{lipics}
\usepackage{amsthm, amsmath}
\usepackage{mathpartir}
\usepackage[references]{agda}
\usepackage{hyperref}

\usepackage{todonotes}
\usepackage{float}
\floatstyle{boxed}
\restylefloat{figure}

\setmainfont[Ligatures=TeX]{XITS}
\setmathfont{XITS Math}

\input{commands.tex}
\usepackage{microtype}

% Author macros::begin %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\title{Certified Proof Search for Intuitionistic Linear Logic}

\author[1]{Guillaume Allais}
\author[1]{Conor McBride}
\affil[1]{University of Strathclyde\\
  Glasgow, Scotland\\
  \texttt{\{guillaume.allais, conor.mcbride\}@strath.ac.uk}}

\authorrunning{G. Allais and C. McBride}
\Copyright{Guillaume Allais, Conor McBride}

\subjclass{F.4.1 Mathematical Logic}

\keywords{Agda, Proof Search, Linear Logic, Certified programming}
% Author macros::end %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\begin{document}
\maketitle

\begin{abstract}
In this article we show the difficulties a type-theorist
may face when attempting to formalise a decidability result
described informally. We then demonstrate how generalising
the problem and switching to a more structured presentation
can alleviate her suffering.

The calculus we target is a fragment of Intuitionistic
Linear Logic (ILL onwards) and the tool we use to construct
the search procedure is Agda (but any reasonable type theory
equipped with inductive families would do). The example is
simple but already powerful enough to derive a solver for
equations over a commutative monoid from a restriction of it.
\end{abstract}

\section{Introduction}

Type theory~\cite{martin-lof:bibliopolis} equipped with
inductive families~\cite{dybjer1994inductive} is expressive
enough that one can implement \emph{certified} proof search
algorithms which are not merely oracles outputting a one bit
answer but full-blown automated provers producing derivations
which are statically known to be correct~\cite{boutin1997using,pollack1995extensibility}.
It is only natural to delve into the literature to try and find
decidability proofs which, through the Curry-Howard correspondence,
could make good candidates for mechanisation (see e.g. Pierre
Crégut's work on Presburger arithmetic~\cite{cregut2004procedure}).
Reality is however not as welcoming as one would hope: most of
these proofs have not been formulated with mechanisation in mind
and would require a huge effort to be ported \emph{as is} in your
favourite theorem prover.

In this article, we argue that it would indeed be a grave
mistake to implement them \emph{as is} and that type-theorists
should aim to develop better-structured algorithms. We show,
working on a fragment of ILL~\cite{girard1987linear}, the sort
of pitfalls to avoid and the generic ideas leading to better-behaved
formulations.

In \autoref{sec:ILL} we describe the fragment of ILL we are
studying; \autoref{sec:general} defines a more general calculus
internalising the notion of leftovers thus making the informal
description of the proof search mechanism formal; and \autoref{sec:contexts}
introduces resource-aware contexts therefore giving us a powerful
language to target with our proof search algorithm implemented
in \autoref{sec:proofsearch}. The soundness and completeness
results, proved respectively in \autoref{sec:soundness} and
\autoref{sec:completeness}, are what let us recover a proof of
the decidability of the ILL fragment considered from the one of
the more general system. Finally, \autoref{sec:application}
presents an application of this proof search procedure to
discharge automatically equations over a commutative monoid.
This solver is then further specialised to proving that two
lists are bag equivalent thus integrating really well with
Danielsson's previous work~\cite{danielsson2012bag}.

\section{The Calculus, Informally\label{sec:ILL}}

Our whole development is parametrised by a type of atomic
proposition \AB{Pr} on which we do not put any constraint
except that equality of its inhabitants should be decidable.
We name \AF{\_≟\_} the function of type (\AB{p} \AB{q} \hasType{}
\AB{Pr}) → \AD{Dec} (\AB{p} \AD{≡} \AB{q}) witnessing this
property.

The calculus we are considering is a fragment of Intuitionistic
Linear Logic composed of \textit{atomic} types (lifting \AB{Pr}),
\textit{tensor} and \textit{with} products. This is summed up by
the following grammar for types:

$$
\text{\AD{ty} ~∷=~ \AIC{κ} \AB{Pr} ~|~ \AD{ty} \tensor{} \AD{ty}
                                   ~|~ \AD{ty} \with{} \AD{ty}}
$$

Sequents (\AB{Γ} \entails{} \AB{σ}) comprise
a multiset of types (\AB{Γ}), the context of available resources,
and a type (\AB{σ}) corresponding to the proposition to be proven.
one is trying to prove. Each type constructor comes with both
introduction and elimination rules (also known as, respectively,
right and left rules because of the side of the sequent they affect)
described in \autoref{fig:ILLRules}. Multisets are inherently
extensional, hence the lack of the permutation rule familiar from
list-based presentations.
\begin{figure*}[h]
\begin{mathpar}
\inferrule{ }{\text{\lmulti{} \AB{σ} \rmulti{} \entails{} \AB{σ}}}{ax}

\and
\inferrule{
     \text{\AB{Γ} \entails{} \AB{σ}}
\and \text{\AB{Δ} \entails{} \AB{τ}}
}{   \text{\AB{Γ} \disjoint{} \AB{Δ} \entails{} \AB{σ} \tensor{} \AB{τ}}
}{\tensor{}^r}

\and
\inferrule{
     \text{\AB{Γ} \disjoint{} \lmulti{} \AB{σ}, \AB{τ} \rmulti{} \entails{} \AB{υ}}
}{   \text{\AB{Γ} \disjoint{} \lmulti{} \AB{σ} \tensor{} \AB{τ} \rmulti{} \entails{} \AB{υ}}
}{\tensor{}^l}
\end{mathpar}
\begin{mathpar}
\inferrule{
     \text{\AB{Γ} \entails{} \AB{σ}}
\and \text{\AB{Γ} \entails{} \AB{τ}}
}{   \text{\AB{Γ} \entails{} \AB{σ} \with{} \AB{τ}}
}{\with{}^r}

\and
\inferrule{
     \text{\AB{Γ} \disjoint{} \lmulti{} \AB{σ} \rmulti{} \entails{} \AB{υ}}
}{   \text{\AB{Γ} \disjoint{} \lmulti{} \AB{σ} \with{} \AB{τ} \rmulti{} \entails{} \AB{υ}}
}{\with{}_1^l}

\and
\inferrule{
     \text{\AB{Γ} \disjoint{} \lmulti{} \AB{τ} \rmulti{} \entails{} \AB{υ}}
}{   \text{\AB{Γ} \disjoint{} \lmulti{} \AB{σ} \with{} \AB{τ} \rmulti{} \entails{} \AB{υ}}
}{\with{}_2^l}
\end{mathpar}
\caption{Introduction and Elimination rules for ILL\label{fig:ILLRules}}
\end{figure*}

However these rules are far from algorithmic: the logician needs to
\emph{guess} when to apply an elimination rule or which partition
of the current context to pick when introducing a tensor. This makes
this calculus really ill-designed for her to perform a proof search
in a sensible manner.
So, rather than sticking to the original presentation and trying
to work around the inconvenience of dealing with rules which are
not algorithmic and intrinsically extensional notions such as the
one of multisets, it is possible to generalise the calculus in order
to have a more palatable formal treatment.

The principal insight in this development is that proof search in
Linear Logic is not just about fully using the context provided to
us as an input in order to discharge a goal. The bulk of the work
is rather to use parts of some of the assumptions in a context to
discharge a first subgoal; collect the leftovers and invest them
into trying to discharge another subproblem. Only in the end should
the leftovers be down to nothing.
This observation leads to the definition of two new notions: first,
the calculus is generalised to one internalising the notion of
leftovers; second, the contexts are made resource-aware meaning
that they keep the same structure whilst tracking whether (parts
of) an assumption has been used already. Proof search becomes
consumption annotation.

\section{Generalising the Problem\label{sec:general}}

In this section, we will start by studying a simple example showcasing
the role the idea of leftovers plays during proof search before diving
into the implementation details of such concepts.

\subsection{Example\label{sec:example}}

Let us study how one would describe the process of running a proof search
algorithm for our fragment of ILL. The intermediate data structures,
despite looking similar to usual ILL sequents, are not quite valid proof
trees as we purposefully ignore left rules. We write
\begin{mathpar}
\text{Δ} \Rightarrow{}
\inferrule{π}{\text{\AB{Γ} \entails{} \AB{σ}}}
\end{mathpar}
to mean that the current proof search state is \AB{Δ} and we managed to
build a pseudo-derivation \AB{π} of type \AB{Γ} \entails{} \AB{σ}. \AB{π}
and \AB{Γ} may be replaced by question marks when we haven't yet reached
a point where we have found a proof and thus instantiated them.

To materialise the idea that some resources in \AB{Δ} are available
whereas others have already been consumed, we are going to mark with a box
\fba{ } (the parts of) the assumptions which are currently available. During
the proof search, the state \AB{Δ} will keep its structure but we will update
its resource annotations. For instance, consuming \AB{σ} out of
\AB{Δ} = \fba{(\AB{σ} \with{} \AB{τ})} \tensor{} \AB{υ} will turn \AB{Δ} into
(\AB{σ} \with{} \fba{\AB{τ}}) \tensor{} \AB{υ}.

Let us now observe how one looks for a proof of the following
formula (where \AB{σ} and \AB{τ} are assumed to be atomic):
(\AB{σ} \tensor{} \AB{τ}) \with{} \AB{σ} \entails{} \AB{τ} \tensor{} \AB{σ}.
The problem we are facing is thus:
\begin{mathpar}
\text{\fba{(\AB{σ} \tensor{} \AB{τ}) \with{} \AB{σ}}}
\Rightarrow
\inferrule{\text{?}
  }{\text{? \entails{} \AB{τ} \tensor{} \AB{σ}}
  }
\end{mathpar}
The goal's head symbol is a \tensor{}; as we have no interest in guessing
whether or not to apply left rules or how to partition the
current context, we simply start by looking for a proof of
its left subformula using the full context. Given that \AB{τ} is an atomic
formula, the only way for us to discharge this goal is to use an assumption
available in the context. Fortunately, there is a \AB{τ} in the context;
we are therefore able to produce a derivation where \AB{τ} has now been
consumed. In terms of our proof search, this is expressed by using an
axiom rule and destructively updating the context:
\begin{mathpar}
\text{\fba{(\AB{σ} \tensor{} \AB{τ}) \with{} \AB{σ}}}
\Rightarrow
\inferrule{\text{?}
  }{\text{? \entails{} \AB{τ}}
  }
\and \rightsquigarrow
\and
\text{(\fba{\AB{σ}} \tensor{} \AB{τ}) \with{} \fba{\AB{σ}}}
\Rightarrow
\inferrule{
}{ \text{\AB{τ} \entails{} \AB{τ}}
}{ax}
\end{mathpar}
The left subgoal done, we can tackle
the right one using the leftovers (\fba{\AB{σ}} \tensor{} \AB{τ})
\with{} \fba{\AB{σ}}. Again we face an atomic formula
which we can discharge only via an assumption. This time there
are two candidates in the context except that one is inaccessible:
solving the previous goal has had the side-effect of picking one
side of the \with{}, rejecting the other entirely. That is,
a left rule has been applied implicitly! The only meaningful
step in the proof search is therefore:
\begin{mathpar}
\text{(\fba{\AB{σ}} \tensor{} \AB{τ}) \with{} \fba{\AB{σ}}}
\Rightarrow
\inferrule{\text{?}
  }{\text{? \entails{} \AB{σ}}
  }
\and \rightsquigarrow
\and
\text{(\AB{σ} \tensor{} \AB{τ}) \with{} \fba{\AB{σ}}}
\Rightarrow
\inferrule{
}{ \text{\AB{σ} \entails{} \AB{σ}}
}{ax}
\end{mathpar}
We can then come back to our \tensor{}-headed goal and combine these
two derivations with the right-rule for \tensor{}. As
(\AB{σ} \tensor{} \AB{τ}) \with{} \fba{\AB{σ}} is a fully used
context (\fba{\AB{σ}} is inaccessible), our
search succeeds:
\begin{mathpar}
\text{(\AB{σ} \tensor{} \AB{τ}) \with{} \fba{\AB{σ}}}
\Rightarrow
\inferrule{
  \inferrule{ }{\text{\AB{τ} \entails{} \AB{τ}}}{ax}
  \and \inferrule{ }{\text{\AB{σ} \entails{} \AB{σ}}}{ax}
}{ \text{(\AB{σ} \tensor{} \AB{τ}) \with{} \AB{σ}
   \entails{} \AB{τ} \tensor{} \AB{σ}}
}{\tensor{}^r}
\end{mathpar}

The fact that the whole context is used by the end of the search
tells us that this should translate into a valid ILL proof tree. And
it is indeed the case: by following the structure of the pseudo-proof
we just generated above and adding the required left rules\footnote{We
will explain in \autoref{sec:soundness} how deciding where these left
rules should go can be done automatically.}, we get the following
derivation.
\begin{mathpar}
\inferrule{
 \inferrule{
  \inferrule{
        \inferrule{ }{\text{\AB{τ} \entails{} \AB{τ}}}{ax}
   \and \inferrule{ }{\text{\AB{σ} \entails{} \AB{σ}}}{ax}
  }{\text{\AB{σ}, \AB{τ} \entails{} \AB{τ} \tensor{} \AB{σ}}
  }{\tensor{}^r}
 }{\text{\AB{σ} \tensor{} \AB{τ} \entails{} \AB{τ} \tensor{} \AB{σ}}
 }{\tensor{}^l}
}{\text{(\AB{σ} \tensor{} \AB{τ}) \with{} \AB{σ} \entails{} \AB{τ} \tensor{} \AB{σ}}
}{\with{}_1^l}
\end{mathpar}

\subsection{A Calculus with Leftovers}

This observation of a proof search algorithm in action leads
us to the definition of a three place relation describing the
new calculus where the notion of leftovers from a subproof is
internalised. When we write down the sequent \AB{Γ} \entails{}
\AB{σ} \coentails{} \AB{Δ}, we mean that from the input \AB{Γ},
we can prove \AB{σ} with leftovers \AB{Δ}. Let us see what a
linear calculus would look like in this setting.

Assuming we already have a similar relation
\AB{Γ} \belongs{} \AB{k} \cobelongs{} \AB{Δ} describing the act of
consuming a resource \AIC{κ} \AB{k}\footnote{In this presentation,
we limit the axiom rule to atomic formulas only but it is not an
issue: it is a well-known fact that an axiom rule for any formula
is admissible by a simple induction on the formula's structure.}
from a context \AB{Γ} with leftovers \AB{Δ}, then the axiom rule
translates to:
\begin{mathpar}
\inferrule{\text{\AB{Γ} \belongs{} \AB{k} \cobelongs{} \AB{Δ}}
}{\text{\AB{Γ} \entails{} \AIC{κ} \AB{k} \coentails{} \AB{Δ}}
}{ax}
\end{mathpar}
The introduction rule for \tensor{} in the system with leftovers does
not involve partitioning a multiset (a list in our implementation)
anymore: one starts by discharging the first subgoal, collects
the leftovers from this computation, and then feeds them to the
procedure now working on the second subgoal.
\begin{mathpar}
\inferrule{
     \text{\AB{Γ} \entails{} \AB{σ} \coentails{} \AB{Δ}}
\and \text{\AB{Δ} \entails{} \AB{τ} \coentails{} \AB{E}}
}{   \text{\AB{Γ} \entails{} \AB{σ} \tensor{} \AB{τ} \coentails{} \AB{E}}}
\end{mathpar}
This is a left-skewed presentation but could just as well be a
right-skewed one. We also discuss (in \autoref{sec:parallel}) the
opportunity for parallelisation of the proof search a symmetric
version could offer as well as the additional costs it would
entail.

The \with{} type constructor on the other hand expects both
subgoals to be proven using the same resources. Formally,
both sides are proved using the input
context and that both leftovers are then synchronised (for a
sensible, yet to be defined, definition of synchronisation).
Obviously, not all leftovers will be synchronisable: checking
whether they are may reject proof candidates which are not
compatible.
\begin{mathpar}
\inferrule{
     \text{\AB{Γ} \entails{} \AB{σ} \coentails{} \AB{Δ₁}}
\and \text{\AB{Γ} \entails{} \AB{τ} \coentails{} \AB{Δ₂}}
\and \text{\AB{Δ} \eqsync{} \AB{Δ₁} \synced{} \AB{Δ₂}}
}{   \text{\AB{Γ} \entails{} \AB{σ} \with{} \AB{τ} \coentails{} \AB{Δ}}}
\end{mathpar}
We can now rewrite (see \autoref{fig:derivation}) the proof
described earlier in a fashion which distinguishes between
the state of the context before one starts proving a goal
and after it has been discharged entirely.
\begin{figure*}
\begin{mathpar}
\inferrule{
  \inferrule{
  }{\text{\fba{(\AB{σ} \tensor{} \AB{τ}) \with{} \AB{σ}}
    \entails{} \AB{τ} \coentails{}
    (\fba{\AB{σ}} \tensor{} \AB{τ}) \with{} \fba{\AB{σ}}}
  }{ax}
  \and
  \inferrule{
  }{\text{(\fba{\AB{σ}} \tensor{} \AB{τ}) \with{} \fba{\AB{σ}}
    \entails{} \AB{σ} \coentails{}
    (\AB{σ} \tensor{} \AB{τ}) \with{} \fba{\AB{σ}}}
  }{ax}
}{\text{\fba{(\AB{σ} \tensor{} \AB{τ}) \with{} \AB{σ}}
        \entails{} \AB{τ} \tensor{} \AB{σ} \coentails{}
        (\AB{σ} \tensor{} \AB{τ}) \with{} \fba{\AB{σ}}}
}{\tensor{}^r}
\end{mathpar}
\caption{A proof with input / output contexts and usage
annotations\label{fig:derivation}}
\end{figure*}

It should not come as a surprise that this calculus does not
have any elimination rule for the various type constructors:
elimination rules do not consume anything, they merely shuffle
around (parts of) assumptions in the context and are, as a
consequence, not interesting proof steps. These are therefore
implicit in the process. This remark resonates a lot with
Andreoli's definition of focusing~\cite{andreoli1992logic}
whose goal was to prune the search space by declaring that the
logician does not care about the order in which some commuting
rules are applied.

Ultimately, these rules being implicit is not an issue as
witnessed by the fact that the soundness result we give in
\autoref{sec:soundness} is constructive: we can mechanically
decide where to optimally insert the appropriate left rules
for the ILL derivation to be correct.

\section{Keeping the Structure\label{sec:contexts}}

We now have a calculus with input and output contexts; but
there is no material artefact describing the relationship
between these two. Sure, we could prove a lemma stating that
the leftovers are precisely the subset of the input context
which has not been used to discharge the goal but the proof
would be quite involved because, among other things, of the
merge operation hidden in the tensor rule.

But this is only difficult because we have forgotten the
structure of the problem and are still dealing with rather
extensional notions. Indeed, all of these intermediate
contexts are just \emph{the} one handed over to us when
starting the proof search procedure except that they come
with an usage annotation describing whether the various
assumptions are still available or have already been
consumed. This is the intuition we used in our example in
\autoref{sec:example} when marking available resources
with a box \fba{ } and keeping used ones rather than simply
dropping them from the context and that is made fully explicit
in \autoref{fig:derivation}.

\subsection{Resource-Aware Contexts}

Let us make this all more formal. We start by defining
\AD{Cover}s: given a type \AB{σ}, a cover \AB{S} is a
formal object describing precisely which \emph{non-empty} set of
parts of \AB{σ} has been consumed already. The set of covers
of a type \AB{σ} is represented by an inductive family \AD{Cover}
\AB{σ} listing all the different ways in which \AB{σ} may be
partially used. The introduction rules can be justified in
the following manner. The cover for an atomic proposition can
only be one thing: the atom itself;

In the case of a tensor, both subparts can be partially used
(cf. \AB{S} \tensor{} \AB{T}) or it may be the case that only
one side has been dug into so far (cf. \AB{S} \tensor \free{τ}
and \free{σ}\tensor{} \AB{T});

Similarly, a cover for a with-headed assumption can be a choice
of a side (cf. \AB{S} \with\free{τ} and \free{σ}\with{} \AB{T}).
Or, more surprisingly, it can be a full cover (cf. \AB{σ} \with{}
\AB{τ}) which is saying that \emph{both} sides will be entirely
used in different subtrees. This sort of full cover is only ever
created when synchronising two output contexts by using a with
introduction rule as in the following example:
\begin{mathpar}
\inferrule{
  \inferrule{ }{\text{\fba{\AB{σ} \with{} \AB{τ}}
                \entails{} \AB{τ} \coentails{}
                \fba{\AB{σ}} \with{} \AB{τ}}}{ax}
  \and
  \inferrule{ }{\text{\fba{\AB{σ} \with{} \AB{τ}}
                \entails{} \AB{σ} \coentails{}
                \AB{σ} \with{} \fba{\AB{τ}}}}{ax}
}{\text{\fba{\AB{σ} \with{} \AB{τ}}
        \entails{} \AB{τ} \with{} \AB{σ} \coentails{}
        \AB{σ} \with{} \AB{τ}}}{\with{}^r}
\end{mathpar}
The \AD{Usage} of a type \AB{σ} is directly based on the idea
of a cover; it describes two different situations: either the
assumption has not been touched yet (it is \emph{mint})
or it has been (partially) used (it is \emph{dented}).
Hence \AD{Usage} is the following datatype with two infix
constructors\footnote{The way the brackets are used is meant to
convey the idea that \AIC{[} \AB{σ} \AIC{]} is in mint condition
whilst \AIC{]} \AB{S} \AIC{[} is dented. The box describing an
hypothesis in mint condition is naturally mimicking the \fba{ }
we have been using earlier on.}:
\begin{mathpar}
\inferrule{
}{\text{\AIC{[} \AB{σ} \AIC{]} \hasType{} \AD{Usage} \AB{σ}}
}
\and \inferrule{\text{\AB{S} \hasType{} \AD{Cover} \AB{σ}}
}{\text{\AIC{]} \AB{S} \AIC{[} \hasType{} \AD{Usage} \AB{σ}}
}
\end{mathpar}
Finally, we can extend the definition of \AD{Usage} to contexts
by a simple pointwise lifting. We call this lifting \AD{Usages}
to retain the connection between the two whilst avoiding any
ambiguities.
\begin{mathpar}
\inferrule{ }{\text{\AIC{ε} \hasType{} \AD{Usages} \AIC{ε}}}
\and \inferrule{
     \text{\AB{Γ} \hasType{} \AD{Usages} \AB{γ}}
\and \text{\AB{S} \hasType{} \AD{Usage} \AB{σ}}
}{   \text{\AB{Γ} \mysnoc{} \AB{S} \hasType{} \AD{Usages} \AB{γ} \mysnoc{} \AB{σ}}}
\end{mathpar}

\paragraph*{Erasures and injections} From \AD{Usage}(\AD{s}), one
can always define a function erasure (\erasure{\_}) listing the formulas
marked as used. Conversely, from a context \AB{γ} the injection
(\AF{inj}) will build the \AD{Usages} \AB{γ} corresponding to a
mint context.

\AgdaHide{
\begin{code}
open import Relation.Nullary
open import Relation.Binary.PropositionalEquality using (_≡_)

module lps-short (Pr : Set) (_≟_ : (x y : Pr) → Dec (x ≡ y)) where

open import Data.Product as Product hiding (map)
open import Function

open import lps.IMLL Pr
open Type
open import lps.Search.Calculus Pr _≟_
open Calculus hiding (_⊢?_)
open import lps.Search.BelongsTo Pr _≟_ as BelongsTo
open BelongsTo.Context hiding (_∋_∈_ ; _∈?_)
open BelongsTo.Type.Cover.FromFree hiding (_∈?[_])
open BelongsTo.Type.Cover.FromDented hiding (_∈?_)
open import lps.Linearity Pr
open LC hiding (｢_｣)
open LT hiding (Usage)

open import lps.Linearity.Action Pr as Action
open Action.Context

open import lib.Nullary
open import lib.Maybe
open import lib.Context as Con
open Con.Context
open Con.Context.Context

pattern ax  k          = `κ k
pattern _⊗ʳ_ a b       = _`⊗ʳ_ a b
pattern _&ʳ_by_ a b pr = _`&ʳ_by_ a b pr

pattern [] = ε

pattern κ   k   = `κ k
pattern _⊗[_] a b = a `⊗[ b ]
pattern [_]⊗_ a b = [ a ]`⊗ b
pattern _&[_] a b = a `&[ b ]
pattern [_]&_ a b = [ a ]`& b
pattern _⊗_ a b = a `⊗ b
pattern _&_ a b = a `& b

｢_｣ : {σ : ty} (S : Cover σ) → Con ty
｢ κ k       ｣ = ε ∙ κ k
｢ A ⊗ B     ｣ = ｢ A ｣ ++ ｢ B ｣
｢ [ a ]⊗ B  ｣ = ｢ B ｣
｢ A ⊗[ b ]  ｣ = ｢ A ｣
｢ a & b     ｣ = ε ∙ (a & b)
｢ A &[ b ]  ｣ = ｢ A ｣
｢ [ a ]& B  ｣ = ｢ B ｣

\end{code}}

\subsection{Being Synchronised, Formally}

Now that \AD{Usages} have been introduced, we can give a formal
treatment of the notion of synchronisation we evoked when giving
the with introduction rule for the calculus with leftovers.
Synchronisation is meant to say that the two \AD{Usages} are equal
modulo some inconsequential variations. These inconsequential
variations partly correspond to the fact that left rules may be
inserted at different places in different subtrees.

Synchronisation is a three place relation \AB{Δ} \eqsync{} \AB{Δ₁}
\synced{} \AB{Δ₂} defined as the pointwise lifting of an analogous
one working on \AD{Cover}s. Let us study the latter one which is
defined in an inductive manner.

It is reflexive which means that its diagonal \AB{S} \eqsync{} \AB{S}
\synced{} \AB{S} is always inhabited. For the sake of simplicity, we
do not add a constructor for reflexivity: this rule is admissible by
induction on \AB{S} based on the fact that synchronisation for covers
comes with all the structural rules one would expect: if two covers'
root constructors are equal and their subcovers are synchronised then
it is only fair to say that both of them are synchronised.

It is also symmetric in its two last arguments which means that for
any \AB{Δ}, \AB{Δ₁}, and \AB{Δ₂}, if \AB{Δ} \eqsync{} \AB{Δ₁} \synced{} \AB{Δ₂}
holds then so does \AB{Δ} \eqsync{} \AB{Δ₂} \synced{} \AB{Δ₁}.

Synchronisation is not quite equality: subderivations may very-well
use different parts of a with-headed assumption without it being
problematic. Indeed: if both of these parts are \emph{entirely}
consumed then it simply means that we will  have to introduce a
different left rule at some point in each one of the subderivations.
This is the only point in the process where we may introduce the
cover \AB{σ} \with{} \AB{τ}. It can take place in different
situations:

The two subderivations may be \emph{fully} using completely different
parts of the assumption\footnote{The definition of the predicate \AD{isUsed}
is basically mimicking the one of \AD{Cover} except that the tensor
constructors leaving one side untouched are disallowed.}:
\begin{mathpar}
\inferrule{\text{\isUsed{\AB{σ}}{\AB{S}}} \and \text{\isUsed{\AB{τ}}{\AB{T}}}
}{\text{\AB{σ} \with{} \AB{τ} \eqsync{} \AB{S} \with\free{\AB{τ}}
                              \synced{} \free{\AB{σ}}\with{} \AB{T}}
}
\end{mathpar}
But it may also be the case that only one of them is using only one
side of the \with{} whilst the other one is a full cover:
\begin{mathpar}
\inferrule{\text{\isUsed{\AB{σ}}{\AB{S}}}
}{\text{\AB{σ} \with{} \AB{τ} \eqsync{} \AB{S} \with\free{\AB{τ}}
                              \synced{} \AB{σ} \with{} \AB{τ}}
}
\and
\inferrule{\text{\isUsed{\AB{τ}}{\AB{T}}}
}{\text{\AB{σ} \with{} \AB{τ} \eqsync{} \free{\AB{σ}}\with{} \AB{T}
                              \synced{} \AB{σ} \with{} \AB{τ}}
}
\end{mathpar}

\subsection{Resource-Aware Primitives}

Now that \AD{Usages} and synchronization are properly defined,
we can make our earlier ternary relations precise.
\begin{mathpar}
\inferrule{\text{\AB{Γ} \hasType{} \AD{Usages} \AB{γ}}
      \and \text{\AB{k} \hasType{} \AD{ℕ}}
      \and \text{\AB{Δ} \hasType{} \AD{Usages} \AB{γ}}
}{\text{\AB{Γ} \belongs{} \AB{k} \cobelongs{} \AB{Δ} \hasType{} \AP{Set}}
}
\and
\inferrule{\text{\AB{Γ} \hasType{} \AD{Usages} \AB{γ}}
      \and \text{\AB{σ} \hasType{} \AD{ty}}
      \and \text{\AB{Δ} \hasType{} \AD{Usages} \AB{γ}}
}{\text{\AB{Γ} \entails{} \AB{σ} \coentails{} \AB{Δ} \hasType{} \AP{Set}}
}
\end{mathpar}

The definition of the calculus has already been given before and
will not be changed. However we can at once define what it means
for a resource to be consumed in an axiom rule. \_\belongs{}\_\cobelongs{}\_
for \AD{Usages} is basically a proof-carrying de Bruijn index~\cite{de1972lambda}.
The proof is stored in the \AIC{zro} constructor and simply leverages
the definition of an analogous \_\belongs{}\_\cobelongs{}\_ for \AD{Usage}.

\begin{mathpar}
\inferrule{\text{\AB{pr} \hasType{} \AB{S} \belongs{} \AB{k} \cobelongs{} \AB{S′}}
}{\text{\AIC{zro} \AB{pr} \hasType{} \AB{Γ} \mysnoc{} \AB{S}
        \belongs{} \AB{k} \cobelongs{}
        \AB{Γ} \mysnoc{} \AB{S′}}
}
\and
\inferrule{\text{\AB{pr} \hasType{} \AB{Γ} \belongs{} \AB{k} \cobelongs{} \AB{Δ}}
}{\text{\AIC{suc} \AB{pr} \hasType{} \AB{Γ} \mysnoc{} \AB{S}
        \belongs{} \AB{k} \cobelongs{}
        \AB{Δ} \mysnoc{} \AB{S}}
}
\end{mathpar}

The definition of \_\belongs{}\_\cobelongs{}\_ for \AD{Usage} is based
on two inductive types respectively describing what it means for a
resource to be consumed out of a mint assumption or out of an existing
cover.

\subsubsection{Consumption from a `Mint' Assumption}

We write \freebelongs{\AB{σ}} \AB{k} \cobelongs{} \AB{S} to mean that
by starting with a completely mint assumption of type \AB{σ}, we
consume \AB{k} and end up with the cover \AB{S} describing the leftovers.

In the case of an atomic formula there is only one solution: to use it
and end up with a total cover:
\begin{mathpar}
\inferrule{
}{\text{\freebelongs{\AIC{κ} \AB{k}} \AB{k} \cobelongs{} \AIC{κ} \AB{k}}
}
\end{mathpar}

In the case of \with{} and \tensor{}, one can decide to dig either left
or right into the assumption to find the right resource. This
gives rise to four similar rules; we show only one example:
left into \tensor{}:
\begin{mathpar}
\inferrule{\text{\freebelongs{\AB{σ}} \AB{k} \cobelongs{} \AB{S}}
}{\text{\freebelongs{\AB{σ} \tensor{} \AB{τ}} \AB{k}
        \cobelongs{} \AB{S} \tensor\free{\AB{τ}}}
}
\end{mathpar}

\subsubsection{Consumption from an Existing Cover}

When we have an existing cover, the situation is slightly more
complicated. First, we can dig into an already partially used
sub-assumption using what we could call structural rules. All
of these are pretty similar so we will only present the one
harvesting the content on the left of \with{}:
\begin{mathpar}
\inferrule{\text{S \belongs{} \AB{k} \cobelongs{} \AB{S′}}
}{\text{S \with\free{\AB{τ}} \belongs{} \AB{k} \cobelongs{} \AB{S′} \with\free{\AB{τ}}}
}
\end{mathpar}
Second, we could invoke the rules defined in the previous paragraphs
to extract a resource from a sub-assumption that had been spared
so far. This can only affect tensor-headed assumption as covers for
with-headed ones imply that we have already picked a side and may not
use anything from the other one. Here is a such rule:
\begin{mathpar}
\inferrule{\text{\freebelongs{\AB{τ}} \AB{k} \cobelongs{} \AB{T}}
}{\text{S \tensor\free{\AB{τ}} \belongs{} \AB{k} \cobelongs{} \AB{S} \tensor{} \AB{T}}
}
\end{mathpar}

We now have a fully formal definition of the more general system
we hinted at when observing the execution of the search procedure
in \autoref{sec:example}. We call this alternative formulation of
the fragment of ILL we have decided to study \textbf{ILLWL} which
stands for \textbf{I}ntuitionistic \textbf{L}inear \textbf{L}ogic
\textbf{Wi}th \textbf{L}eftovers. It will only be useful if it is
equivalent to ILL. The following two sections are dedicated to
proving that the formulation is both sound (all the derivations in
the generalised calculus give rise to corresponding ones in ILL)
and complete (if a statement can be proven in ILL then a corresponding
one is derivable in the generalised calculus).

\section{Completeness\label{sec:completeness}}

The purpose of this section is to prove the completeness of our
generalised calculus: to every derivation in ILL we can associate
a corresponding one in the consumption-based calculus.

One of the major differences between the two calculi is that in the
one with leftovers, the context decorated with consumption annotations
is the same throughout the whole derivation whereas we constantly chop
up the multiset of resources in ILL. To go from ILL to ILLWL,
we need to introduce a notion of weakening which give us the ability to
talk about working in a larger context.

\subsection{A Notion of Weakening for ILLWL}

A particular feature of Linear Logic is precisely that there is no
notion of weakening allowing you to discard resources without using them. In
the calculus with leftovers however, it is perfectly sensible to talk
about resources which are not impacted by the proof process: they are
merely passed around and returned untouched at the end of the computation.
Given, for instance, a derivation \AB{S} \entails{} \AB{G} \coentails{T}
\footnote{We write \AB{S} for \AIC{ε} \AIC{∙}\AIC{]} \AB{S} \AIC{[} in
order to lighten the presentation} in our calculus with leftovers, it
makes sense to apply the same extension of the context to both the input
and output context:

\begin{center}
\begin{tikzpicture}
  \draw[black, thick]
     (0   , 0)   --
     (0.5 , 0)   --
     (0.5 , 0.5) --
     (1.5 , 0.5) --
     (1.5 , 0)   --
     (2   , 0)   --
     (2   , 0.5) --
     (1   , 1.5) --
     (0.5 , 1.5) --
     (0   , 1)   --
     cycle;
  \draw[black]
     (0.25 , 0.4) --
     (0.25 , 1)   --
     (0.6  , 1.25);
  \draw[black]
     (1.25 , 0.9)  --
     (1.25 , 1)    --
     (0.9  , 1.25);
  \draw[black]
     (1.1 , 0.75) --
     (1   , 0.6)  --
     (1   , 0.4);
  \draw[black]
     (1.4  , 0.75) --
     (1.75 , 0.6)  --
     (1.75 , 0.4);
  \node[draw=none] at (0.25 , 0.25) {\AIC{[}\AB{α}\AIC{]}};
  \node[draw=none] at (0.75 , 1.25) {\AIC{\&}};
  \node[draw=none] at (1.25 , 0.75) {\AIC{⊗}};
  \node[draw=none] at (1    , 0.25) {\AB{S}};
  \node[draw=none] at (1.75 , 0.25) {\AB{β}};
  \node[draw=none] at (2.2  , 0.25) {\AD{⊢}};
  \node[draw=none] at (2.5  , 0.25) {\AB{G}};
  \node[draw=none] at (2.8  , 0.25) {\coentails{}};
  \draw[black, thick]
     (3   , 0)   --
     (3.5 , 0)   --
     (3.5 , 0.5) --
     (4.5 , 0.5) --
     (4.5 , 0)   --
     (5   , 0)   --
     (5   , 0.5) --
     (4   , 1.5) --
     (3.5 , 1.5) --
     (3   , 1)   --
     cycle;
  \draw[black]
     (3.25 , 0.4) --
     (3.25 , 1)   --
     (3.6  , 1.25);
  \draw[black]
     (4.25 , 0.9)  --
     (4.25 , 1)    --
     (3.9  , 1.25);
  \draw[black]
     (4.1 , 0.75) --
     (4   , 0.6)  --
     (4   , 0.4);
  \draw[black]
     (4.4  , 0.75) --
     (4.75 , 0.6)  --
     (4.75 , 0.4);
  \node[draw=none] at (3.25 , 0.25) {\AIC{[}\AB{α}\AIC{]}};
  \node[draw=none] at (3.75 , 1.25) {\AIC{\&}};
  \node[draw=none] at (4.25 , 0.75) {\AIC{⊗}};
  \node[draw=none] at (4    , 0.25) {\AB{T}};
  \node[draw=none] at (4.75 , 0.25) {\AB{β}};
\end{tikzpicture}
\end{center}

These considerations lead us to examine the notion of \AD{Usage}(\AD{s})
extensions describing systematically how one may enrich a context and to
prove their innocuousness when it comes to derivability.

\subsubsection{\AD{Usage} extensions}

We call \AB{h}-\AD{Usage} extension of type \AB{σ} (written \uext{\AB{h}}{\AB{σ}})
the description of a structure containing exactly one hole denoted \hole{}
into which, using \_\fillU{}\_, one may plug an \AD{Usage} \AB{h} in order
to get an \AD{Usage} \AB{σ}. For instance, one may have a hole on the right
hand side of a tensor product (where \_\AF{⊗U}\_ is the intuitive
lifting of tensor to \AD{Usage} unpacking both sides and outputting
the appropriate annotation):

\begin{mathpar}
\inferrule{
  \text{\AB{L} \hasType{} \AD{Usage} \AB{σ}}
  \and \text{\AB{R} \hasType{} \uext{\AB{h}}{\AB{τ}}}
  }{\text{\AB{L} \tensor\hole{\AB{R}} \hasType{} \uext{\AB{h}}{\AB{σ} \tensor{} \AB{τ}}}
  }
\and \inferrule{}{\text{\AB{H} \fillU{} \AB{L} \tensor\hole{\AB{R}} =
                        \AB{L} \AF{⊗U} (\AB{H} \fillU{} \AB{R})}}
\end{mathpar}

\subsubsection{\AD{Usages} extensions}

\AD{Usages} extensions are akin to Altenkirch et al.'s Order Preserving
Embeddings~\cite{altenkirch1995categorical} except that they allow the
modification of the individual elements which are embedded in the larger
context using a \AD{Usage} extension. We list below the three OPE
constructors together with the corresponding cases of \_\fillUs{}\_
describing how to transport a \AD{Usages} along an extension.
One can embed the empty context into any other context, extend the head
\AD{Usage} using the tools defined in the previous subsection, or simply
throw in an entirely new \AD{Usage}:

\begin{mathpar}
\inferrule{\text{\AB{Δ} \hasType{} \AD{Usages} \AD{δ}}
  }{\text{\AIC{ε} \AB{Δ} \hasType{} \usext{\AIC{ε}}{\AB{δ}}}
  }
\and \inferrule{}{\text{\AIC{ε} \fillUs{} \AIC{ε} \AB{Δ} = \AB{Δ}}}
\end{mathpar}
\begin{mathpar}
\inferrule{
    \text{\AB{hs} \hasType{} \usext{\AB{γ}}{\AB{δ}}}
    \and \text{\AB{h} \hasType{} \uext{\AB{σ}}{\AB{τ}}}
  }{\text{\AB{hs} \mysnoc{} \AB{h} \hasType{} \usext{\AB{γ} \mysnoc{} \AB{σ}}{\AB{δ} \mysnoc{} \AB{τ}}}
  }
\and \inferrule{}{\text{\AB{Γ} \mysnoc{} \AB{S} \fillUs{} \AB{hs} \mysnoc{} \AB{h} =
                   (\AB{Γ} \fillUs{} \AB{hs}) \mysnoc{} (\AB{S} \fillU{} \AB{h}})}
\end{mathpar}
\begin{mathpar}
\inferrule{
    \text{\AB{hs} \hasType{} \usext{\AB{γ}}{\AB{δ}}}
    \and \text{\AB{S} \hasType{} \AD{Usage} \AB{σ}}
  }{\text{\AB{hs} \AIC{∙′} \AB{S} \hasType{} \usext{\AB{γ}}{\AB{δ} \mysnoc{} \AB{σ}}}
  }
\and \inferrule{}{\text{\AB{Γ} \fillUs{} \AB{hs} \AIC{∙′} \AB{S} =
                   (\AB{Γ} \fillUs{} \AB{hs}) \mysnoc{} \AB{S}}}
\end{mathpar}

This machinery defined, we can easily state and prove the
following simple weakening lemma:

\begin{lemma}[Weakening for ILLWL]
Given \AB{Γ} and \AB{Δ} two \AD{Usages} \AB{γ} and a goal \AB{σ}
such that \AB{Γ} \entails{} \AB{σ} \coentails{} \AB{Δ} holds true,
for any \AB{hs} of type \usext{\AB{γ}}{\AB{δ}}, it holds that:
\AB{Γ} \fillUs{} \AB{hs} \entails{} \AB{σ} \coentails{} \AB{Δ} \fillUs{} \AB{hs}.
\end{lemma}
\begin{proof}The proof is by induction on the derivation
\AB{Γ} \entails{} \AB{σ} \coentails{} \AB{Δ} and relies on intermediate
lemmas corresponding to the definition of weakening for \_\belongs{}\_\cobelongs{}\_
and \_\eqsync{}\_\synced{}\_.
\end{proof}

\subsection{Proof of completeness}

The first thing to do is to prove that the generalised axiom rule
given in ILL is admissible in ILLWL.

\begin{lemma}[Admissibility of the Axiom Rule]Given a type \AB{σ}, one
can find \AB{S}, a full \AD{Usage} \AB{σ}, such that
\injs{} (\AIC{ε} \mysnoc{} \AB{σ}) \entails{} \AB{σ} \coentails{} \AIC{ε} \mysnoc{} \AB{S}.
\end{lemma}
\begin{proof}By induction on \AB{σ}, using weakening to be able to combine
the induction hypotheses.
\end{proof}

The admissibility of the axiom rule allows us to prove completeness
by a structural induction on the derivation:

\begin{theorem}[Completeness]Given a context \AB{γ} and a type \AB{σ}
such that \AB{γ} \entails{} \AB{σ}, we can prove that there exists \AB{Γ}
a \emph{full} \AD{Usages} \AB{γ} such that \inj{} \AB{γ} \entails{} \AB{σ} \coentails{} \AB{Γ}.
\end{theorem}
\begin{proof}The proof is by induction on the derivation \AB{γ} \entails{} \AB{σ}.

\underline{Axiom} The previous lemma is precisely dealing with this case.

\underline{With Introduction} is combining the induction hypotheses
by using the fact that two full \AD{Usages} are always synchronisable
and their synchronisation is a full \AD{Usages}.

\underline{Tensor Introduction} relies on the fact that the (proof
relevant) way in which the two premises' contexts are merged gives
us enough information to generate the appropriate \AD{Usages} extensions
along which to weaken the induction hypotheses. The two weakened
derivations are then proven to be compatible (the weakened output
context of the first one is equal to the weakened input of the
second one) and combined using a tensor introduction rule whose
output context is indeed fully used.

\underline{Left rules} The left rules are dealt with by defining
ad-hoc functions mimicking the action of splitting a variable in
the context (for tensor) or picking a side (for with) at the
\AD{Usages} level and proving that these actions do not affect
derivability in ILLWL negatively.
\end{proof}

This is overall a reasonably simple proof but it had to be expected:
ILL is more explicit, listing each
left-rule application whereas ILLWL is more elliptic.
Let us now turn to soudness.

\section{Soundness\label{sec:soundness}}

The soundness result tells us that from a derivation in the more
general calculus, one can create a valid derivation in ILL. To
be able to formulate such a statement, we need a way of listing
the assumptions which have been used in a proof \AB{Γ} \entails{}
\AB{σ} \coentails{} \AB{Δ}; informally, we should be able to describe
a \AD{Usages} \AB{E} such that \erasure{E} \entails{} \AB{σ}. To that effect,
we introduce the notion of difference between two usages.

\subsection{Usages Difference}

A \AD{Usages} difference \AB{E} between \AB{Γ} and \AB{Δ} (two elements of
type \AD{Usages} \AB{γ}) is a \AD{Usages} \AB{γ} such that \AB{Δ}
\eqsync{} \AB{Γ} \AD{─} \AB{E} holds where the three place relation
\_\eqsync{}\_\AD{─}\_ is defined as the pointwise lifting of a relation
on \AD{Usage}s. This inductive datatype, itself based on a definition of
cover differences, distinguishes three cases: if the input and the output
are equal then the difference is a mint assumption, if the input was a
mint assumption then the difference is precisely the output \AD{Usage}
and, finally, we may also be simply lifting the notion of \AD{Cover}
difference when both the input and the output are dented.

Cover differences (\_\eqsync{}\_\diff{}\_) are defined by an
inductive type described (minus the expected structural laws which we
let the reader infer) in \autoref{fig:coverdiffs}.
\begin{figure*}[h]
\begin{mathpar}
\inferrule{ \text{\AB{S} \eqsync{} \AB{S₁} \diff{} \AB{S₂}}
}{\text{\AB{S} \tensor{} \AB{T} \eqsync{} \AB{S₁} \tensor{} \AB{T}
                                \diff{} \AB{S₂} \tensor\AIC{[} \AB{τ} \AIC{]}}
}
\and
\inferrule{ \text{\AB{S} \eqsync{} \AB{S₁} \diff{} \AB{S₂}}
}{\text{\AB{S} \tensor{} \AB{T} \eqsync{} \AB{S₁} \tensor\AIC{[} \AB{τ} \AIC{]}
                                \diff{} \AB{S₂} \tensor{} \AB{T}}
}
\end{mathpar}
\begin{mathpar}
\inferrule{ \text{\AB{T} \eqsync{} \AB{T₁} \diff{} \AB{T₂}}
}{\text{\AB{S} \tensor{} \AB{T} \eqsync{} \AB{S} \tensor{} \AB{T₁}
                                \diff{} \AIC{[} \AB{σ} \AIC{]}\tensor{} \AB{T₂}}
}
\and
\inferrule{\text{\AB{T} \eqsync{} \AB{T₁} \diff{} \AB{T₂}}
}{\text{\AB{S} \tensor{} \AB{T} \eqsync{} \AIC{[} \AB{σ} \AIC{]}\tensor{} \AB{T₁}
                                \diff{} \AB{S} \tensor{} \AB{T₂}}
}
\end{mathpar}
\begin{mathpar}
\inferrule{
}{\text{\AB{S} \tensor{} \AB{T} \eqsync{} \AIC{[} \AB{σ} \AIC{]}\tensor{} \AB{T}
                                \diff{} \AB{S} \tensor\AIC{[} \AB{τ} \AIC{]}}
}
\and
\inferrule{
}{\text{\AB{S} \tensor{} \AB{T} \eqsync{} \AB{S} \tensor\AIC{[} \AB{τ} \AIC{]}
                                \diff{} \AIC{[} \AB{σ} \AIC{]}\tensor{} \AB{T}}
}
\end{mathpar}
\caption{\AD{Cover} differences\label{fig:coverdiffs}}
\end{figure*}

\subsection{Soundness Proof}

The proof of soundness is split into auxiliary lemmas which are
used to combine the induction hypotheses. These lemmas, where the
bulk of the work is done, are maybe the places where the precise
role played by the constraints enforced in the generalised calculus
come to light. We state them here and skip the relatively tedious
proofs. The interested reader can inspect the \file{Search/Calculus}
file.

\begin{lemma}[Introduction of with]
Assuming that we are given two subproofs
    \AB{Δ₁} \eqsync{} \AB{Γ} \diff{} \AB{E₁}
and \erasure{\AB{E₁}} \entails{} \AB{σ}
on one hand and
    \AB{Δ₂} \eqsync{} \AB{Γ} \diff{} \AB{E₂}
and \erasure{\AB{E₂}} \entails{} \AB{τ}
on the other,
and that we know that the two \AD{Usages} \AB{γ} respectively called
\AB{Δ₁} and \AB{Δ₂} are such that
    \AB{Δ} \eqsync{} \AB{Δ₁} \synced{} \AB{Δ₂}
then we can generate \AB{E}, an \AD{Usages} \AB{γ}, such that
    \AB{Δ} \eqsync{} \AB{Γ} \diff{} \AB{E},
    \erasure{\AB{E}} \entails{} \AB{σ},
and \erasure{\AB{E}} \entails{} \AB{τ}.
\end{lemma}
\begin{proof}By structural induction on the
derivation stating that \AB{Δ₁} and \AB{Δ₂} are synchronised.
\end{proof}

We can prove a similar theorem corresponding to the introduction of
a tensor constructor. We write \AB{E} \eqsync{} \AB{E₁} \AD{⋈} \AB{E₂}
to mean that the context \AB{E} is obtained by interleaving \AB{E₁}
and \AB{E₂}. This notion is defined inductively and, naturally, is
proof-relevant. It corresponds in our list-based formalisation of ILL
to the multiset union mentioned in the tensor introduction rule in
\autoref{fig:ILLRules}.


\begin{lemma}[Introduction of tensor]
Given \AB{F₁} and \AB{F₂} two \AD{Usages} \AB{γ} such that:
    \AB{Δ} \eqsync{} \AB{Γ} \diff{} \AB{F₁}
and \erasure{\AB{F₁}} \entails{} \AB{σ}
on one hand and
    \AB{E} \eqsync{} \AB{Δ} \diff{} \AB{F₂}
and \erasure{\AB{F₂}} \entails{} \AB{τ}
on the other, then we can generate \AB{F} an \AD{Usages} \AB{γ}
together with two contexts \AB{E₁} and \AB{E₂} such that:
    \AB{E} \eqsync{} \AB{Γ} \diff{} \AB{F},
    \erasure{\AB{F}} \eqsync{} \AB{E₁} \AD{⋈} \AB{E₂},
    \AB{E₁} \entails{} \AB{σ}
and \AB{E₂} \entails{} \AB{τ}
\end{lemma}

\begin{theorem}[Soundness of the Generalisation]
For all context \AB{γ}, all \AB{Γ}, \AB{Δ} of type \AD{Usages}
\AB{γ} and all goal \AB{σ} such that \AB{Γ} \entails{} \AB{σ}
\coentails{} \AB{Δ} holds, there exists an \AB{E} such that
\AB{Δ} \eqsync{} \AB{Γ} \AD{─} \AB{E} and \erasure{\AB{E}}
\entails{} \AB{σ}.
\end{theorem}
\begin{proof}
The proof is by induction on the derivation; using auxiliary
lemmas to combine the induction hypothesis.
\end{proof}

\begin{corollary}[Soundness of the Proof Search]
If the proof search shows that \AF{inj} \AB{γ} \entails{} \AB{σ}
\coentails{} \AB{Δ} holds for some \AB{Δ} and \AB{Δ} is a
full usage then \AB{γ} \entails{} \AB{σ}.
\end{corollary}

The soundness result relating the new calculus to the original
one makes explicit the fact that valid ILL derivations correspond
to the ones in the generalised calculus which have no leftovers.
Together with the completeness result it implies that if we can
write a decision procedure for ILLWL then we will automatically
have one for ILL.

\section{Proof Search\label{sec:proofsearch}}

We have defined a lot of elegant datatypes so far but the original
goal was to implement a proof search algorithm for the fragment of
ILL we have decided to study. The good news is that all the systems
we have described have algorithmic rules: read bottom-up, they are
a set of constructor-directed recipes to search for a proof. Depending
on the set of rules however, they may or may not be deterministic
and they clearly are not total because not all sequents are provable.
This simply means that we will be working in various monads. The axiom
rule forces us to introduce non-determinism (which we will model using
the list monad); there are indeed as many ways of proving an atomic
proposition as there are assumptions of that type in the context. The
rule for tensor looks like two stateful operations being run sequentially:
one starts by discharging the first subgoal, waits for it to \emph{return}
a modified context and then threads these leftovers to tackle the second
one. And, last but not least, the rule for with looks very much like a
map-reduce diagram: we start by generating two subcomputations which can
be run in parallel and later on merge their results by checking whether
the output contexts can be said to be synchronised (and this failure
will be dealt with using the maybe monad).

Now, the presence of these effects is a major reason why it is important
to have the elegant intermediate structures we can generate inhabitants
of. Even if we are only interested in the satisfiability of a given
problem, having material artefacts at our disposal allows us to state
and prove properties of these functions easily rather than having to
suffer from boolean blindness: ``A Boolean is a bit uninformative''~\cite{mcbride2005epigram}.
And we know that we may be able to optimise them
away~\cite{wadler1990deforestation, gill1993short} in the case where
we are indeed only interested in the satisfiability of the problem and
they turn out to be useless.

The proof search procedures are rather simple to implement (they
straightforwardly follow the specifications we have spelled out
earlier) and their definitions are succinct.

\begin{theorem}Given a \AB{Γ} of type \AD{Usages} \AB{γ} and an atomic
proposition \AB{k}, one can produce a list of pairs consisting of a
\AD{Usages} \AB{γ} we will call \AB{Δ} and a proof that
\AB{Γ} \belongs{} \AB{k} \cobelongs{} \AB{Δ}.
\end{theorem}
\begin{proof}
It amounts to calling on each element of the context the appropriate
auxiliary search procedures describing how to extract an atomic
proposition from respectively a mint or a dented assumption and
apply a lemma to transport the resulting proofs.
\end{proof}

\begin{theorem}[Proof Search] Given an \AB{S} of type \AD{Usage} \AB{σ}
and a type \AB{τ}, it is possible to produce a list of pairs consisting
of a \AD{Usage} \AB{σ} we will call \AB{T} and a proof that
\AB{S} \entails{} \AB{τ} \coentails{} \AB{T}.
\end{theorem}

\subsection{From Proof Search to a Decision Procedure}

The only thing missing in order for us to have a decision procedure is a
proof that all possible \emph{interesting} cases are considered by
the proof search algorithm. The ``interesting'' keyword is here very
important. In the \_\belongs{}\_\cobelongs{}\_ case, it is indeeed
crucial that we try all potential candidates as future steps may
reject subproofs.

\begin{lemma}[No Overlooked Assumption] Given \AB{Γ}, \AB{Δ} two
\AD{Usages} \AB{γ} and \AB{k} an atom such that there is a proof
\AB{pr} that \AB{Γ} \belongs{} \AB{k} \cobelongs{} \AB{Δ} holds,
\AB{k} \AF{∈?} \AB{Γ} contains the pair (\AB{Δ} \AIC{,} \AB{pr}).
\end{lemma}

In the \_\eqsync{}\_\synced{}\_ case, however, it is not as important:
the formalisation is made shorter by having a constructor for symmetry
rather than twice as many introduction rules. This does not mean that
we are interested in the proofs where one spends time applying symmetry
over and over again. As a consequence, we have to acknowledge the fact
that the proof discovered by the search procedure may be different
from any given proof of the same type. And this constraint is propagated
all the way up to the main theorem

\begin{theorem}[No Overlooked Derivation] Given \AB{Γ}, \AB{Δ}
two \AD{Usages} \AB{γ} and \AB{σ} a type, if \AB{Γ} \entails{}
\AB{σ} \coentails{} \AB{Δ} holds then there exists a derivation
\AB{pr} of \AB{Γ} \entails{} \AB{σ} \coentails{} \AB{Δ} such that
the pair (\AB{Δ} \AIC{,} \AB{pr}) belongs to the list
\AB{Γ} \AF{⊢?} \AB{σ}.
\end{theorem}

From this result, we can conclude that we have in practice defined
a decision procedure for ILLWL and therefore ILL as per the
soundness and completeness results proven in \autoref{sec:soundness}
and \autoref{sec:completeness} respectively.


\section{Applications: building Tactics\label{sec:application}}

The theory of ILL with just atomic propositions and tensor products
is exactly the one of bag equivalence: a goal will be provable if
and only if the multiset of its atomic propositions is precisely
the context's one.

Naturally, one may want to write a solver for Bag Equivalence
based on the one for ILL. But it is actually possible to solve
an even more general problem: equations on a commutative monoid.
Agda's standard library comes with a solver for equations on a
semiring but it's not always the case that one has such a rich
structure to take advantage of.

Given an abstract syntax tree representing an expression over
a monoid \AB{M} composed of constants and variables, it is
possible to produce a semantically equivalent pair of a constant
and a multiset of variables. Testing equality of expressions is
now reduced to testing equality of these normal forms. And it is
easy to do so: they are equal if their first components are and
their second ones are the same multisets. This is where our solver
for ILL steps in: if we limit the context to atoms only and the
goal to being one big tensor of atomic formulas then we prove
precisely multiset equality. We call \AF{proveMonEq} the prover
we derive from these observations.

Now, the standard library already contains a proof that (\AD{ℕ}, \AN{0},
\AF{\_+\_}) is a commutative monoid so we can use this fact to have a look
at an example. In the following code snippet, \AF{LHS}, \AF{RHS} and
\AF{CTX} are respectively reified\footnote{All these reification
are currently done by hand but could be automated. These issues
have been thoroughly dealt with by Van Der Walt and Swierstra~\cite{van2012reflection,van2013engineering}.}
versions of the left and right hand sides of the equation and a
valuation mapping variables language to their names in Agda.

\AgdaHide{
\begin{code}
open import Algebra
open import Algebra.Structures
open CommutativeMonoid
open import Level

module TacticsAbMonPaper
         (Mon : CommutativeMonoid zero zero)
         (_≟_ : (x y : Carrier Mon) → Dec (x ≡ y)) where

  open import Data.Nat
  open import Data.Fin
  open import Data.Vec
  open import Algebra
  open import Algebra.Structures

  module M = CommutativeMonoid Mon

  infixl 6 _`∙_

  data Expr (n : ℕ) : Set where
    `v    : (k : Fin n)         → Expr n
    `c    : (el : Carrier Mon)  → Expr n
    _`∙_  : (t u : Expr n)      → Expr n

  Valuation : ℕ → Set
  Valuation n = Vec M.Carrier n

  ⟦_⟧^E : {n : ℕ} (t : Expr n) (ρ : Valuation n) → M.Carrier
  ⟦ `v k    ⟧^E ρ = lookup k ρ
  ⟦ `c el   ⟧^E ρ = el
  ⟦ t `∙ u  ⟧^E ρ = ⟦ t ⟧^E ρ M.∙ ⟦ u ⟧^E ρ

  open import Prelude as Prelude hiding (_×_ ; Fin ; _$_ ; flip ; lookup)

  Model : (n : ℕ) → Set
  Model n = M.Carrier × List (Fin n)

  ⟦_⟧^Ms : {n : ℕ} (ks : List (Fin n)) (ρ : Valuation n) → M.Carrier
  ⟦ ks ⟧^Ms ρ = Prelude.foldr M._∙_ M.ε (Prelude.map (flip lookup ρ) ks)

  ⟦_⟧^M : {n : ℕ} (t : Model n) (ρ : Valuation n) → M.Carrier
  ⟦ el , ks ⟧^M ρ = el M.∙ ⟦ ks ⟧^Ms ρ

  _∙∙_ : {n : ℕ} → Model n → Model n → Model n
  (e , ks) ∙∙ (f , ls) = e M.∙ f , ks Prelude.++ ls

  norm : {n : ℕ} (t : Expr n) → Model n
  norm (`v k)    = M.ε  , k ∷ Prelude.[]
  norm (`c el)   = el   , Prelude.[]
  norm (t `∙ u)  = norm t ∙∙ norm u

module ExamplesTactics where

  open import Algebra.Structures
  open import Data.Nat as Nat
  open import Data.Nat.Properties
  open import Data.List
  module AbSR = IsCommutativeSemiring isCommutativeSemiring

  open import Data.Fin as Fin hiding (_+_)
  open import Data.Vec as Vec
  open import lps.Tactics
  module ℕ+ = TacticsAbMon (record
                        { Carrier = ℕ
                        ; _≈_ = _≡_
                        ; _∙_ = _+_
                        ; ε   = 0
                        ; isCommutativeMonoid = AbSR.+-isCommutativeMonoid
                        }) Nat._≟_
  import Prelude as Pr
\end{code}}

\begin{code}
  2+x+y+1 : (x y : Nat.ℕ) → 2 + (x + y + 1) ≡ y + 3 + x
  2+x+y+1 x y = proveMonEq LHS RHS CTX
\end{code}
\AgdaHide{
\begin{code}
    where  open ℕ+
           `x   = `v (Fin.# 0)
           `y   = `v (Fin.# 1)
           LHS  = `c 2 `∙ ((`x `∙ `y) `∙ `c 1)
           RHS  = (`y `∙ `c 3) `∙ `x
           CTX  = x Vec.∷ y Vec.∷ Vec.[]
\end{code}}

The normalization step reduced proving this equation to proving
that the pair (\AN{3}, \lmulti{}\AB{x}, \AB{y}\rmulti{}) is equal
to the pair (\AN{3}, \lmulti{}\AB{y}, \AB{x}\rmulti{}). Equality
of the first components is trivial whilst the multiset equality
one is proven true by our solver.

A solver for bag equivalence can be derived by observing that for
all \AB{A}, (\AD{List} \AB{A}, \AF{\_++\_}, \AIC{[]}) is a commutative
monoid for the equivalence relation \AF{\_≈-bag\_}.

\AgdaHide{
\begin{code}
  open import Bag-equivalence
  module BE = BagEq Nat.ℕ Nat._≟_

  sgl : ℕ → Pr.List ℕ
  sgl x = x Pr.∷ Pr.[]

  example : (xs ys : Pr.List Nat.ℕ) → 
    1 Pr.∷ 2 Pr.∷ xs Pr.++ 1 Pr.∷ ys ≈-bag  ys Pr.++ 2 Pr.∷ xs Pr.++ 1 Pr.∷ 1 Pr.∷ Pr.[]
  example xs ys = proveMonEq LHS RHS CTX
    where open BE
          `1   = `v (Fin.# 0)
          `2   = `v (Fin.# 1)
          `xs  = `v (Fin.# 2)
          `ys  = `v (Fin.# 3)
          LHS  = ((`1 `∙ `2) `∙ `xs) `∙ `1 `∙ `ys
          RHS  = `ys `∙ (`2 `∙ `xs) `∙ `1 `∙ `1
          CTX  = sgl 1 Vec.∷ sgl 2 Vec.∷ xs Vec.∷ ys Vec.∷ Vec.[]
\end{code}}

\section{Conclusion, Related and Future Work\label{sec:related}}

We have seen how, starting from provability in Intuitionistic
Linear Logic, a problem with an extensional formulation, we
can move towards a type-theoric approach to solving it. This
was done firstly by generalising the problem to a calculus
with leftovers better matching the proof search process and
secondly by introducing resource-aware contexts which are
datatypes retaining the important hidden \emph{structure}
of the problem. These constructions led to the definition of
Intuitionistic Linear Logic With Leftovers, a more general
calculus enjoying a notion of weakening but, at the same time,
sound and complete with respect to ILL. Provability of formulas
in ILL being decidable is then a simple corollary of it being
decidable for ILLWL. Finally, a side effect of this formalization
effort is the definition of helpful tactics targetting commutative
monoids and, in particular, bag equivalence of lists.


This development has evident connections with Andreoli's vastly
influential work on focusing in Linear Logic~\cite{andreoli1992logic}
which demonstrates that by using a more structured calculus (the
focused one), the logician can improve her proof search procedure
by making sure that she ignores irrelevant variations between proof
trees. The fact that our approach is based on never applying a left
rule explicitly and letting the soundness result insert them in an
optimal fashion is in the same vein: we are, effectively, limiting
the search space to proof trees with a very specific shape without
losing any expressivity.



In the domain of certified proof search, Kokke and Swierstra
have designed a prolog-style procedure in Agda~\cite{kokkeauto}
which, using a fuel-based model, will explore a bounded part of
the set of trees describing the potential proofs generated by
backward-chaining using a fixed set of deduction rules as methods.

As already heavily hinted at by the previous section, there is a
number of realms which benefit from proof search in Linear Logic.
Bag equivalence~\cite{danielsson2012bag} is clearly one of them
but recent works also draw connections between Intuitionistic
Linear Logic and narrative representation, proof search then
becomes narrative generation~\cite{bosser2011structural,martens2013linear,bosser2010linear} and a proof is seen as a trace corresponding to one
possible storyline given the plot-devices available in the context.
Our approach is certified to produce all possible derivations
(modulo commuting the application of the left rules) and therefore
all the corresponding storylines.

\subsection{Tackling a Larger Fragment}

The fragment we are studying is non-trivial: as showcased, having
only tensor and atomic formulas would already be equivalent to testing
bag equivalence between the context and the goal; limiting ourselves
to with and atomic formulas would amount to checking that there is a
non-empty intersection between the context and the goal. However mixing
tensors and withs creates a more intricate theory hence this whole
development. It would nonetheless be exciting to tackle a larger
fragment in a similar, well-structured manner.

A very important connector in ILL is the lollipop. Although dealing
with it on the right hand side is extremely simple (one just extends
the context with the newly acquired assumption and check that it has
been entirely consumed in the subderivation corresponding to the body
of the lambda abstraction), its elimination rule is more complex: if
\AB{σ} \lolli{} \AB{τ} belongs to the context, then one needs to be
able to make this specific assumption temporarily unavailable when
proving its premise. Indeed, it would otherwise be possible to use its
own body to discharge the premise thus leading to a strange fixpoint
making e.g. \AB{σ} \lolli{} (\AB{σ} \tensor{} \AB{σ}) \entails{} \AB{σ}
provable. We have explored various options but still have to come up
with a well-structured solution.

\subsection{Search Parallelisation\label{sec:parallel}}

The reader familiar with linear logic will not have been surprised
by the fact that some rules are well-suited for a parallel exploration
of the provability of its sub-constituents. The algorithm we have
presented however remains sequential when it comes to a goal whose
head symbol is a tensor. But that is not a fatality: it is possible
to design a tensor introduction rule following the map-reduce approach
seen earlier. It will let us try to produce both subproofs in parallel
before performing an \textit{a posteriori} check to make sure that the
output contexts of the two subcomputations are disjoint.
\begin{mathpar}
\inferrule{
     \text{\AB{Γ} \entails{} \AB{σ} \coentails{} \AB{Δ₁}}
\and \text{\AB{Γ} \entails{} \AB{τ} \coentails{} \AB{Δ₂}}
\and \text{\AB{Δ} \eqsync{} \AB{Δ₁} \disjoint{} \AB{Δ₂}}
}{   \text{\AB{Γ} \entails{} \AB{σ} \tensor{} \AB{τ} \coentails{} \AB{Δ}}}
\end{mathpar}
This approach would allow for a complete parallelisation of the
work at the cost of more subproofs being thrown away at the merge
stage because they do not fit together.

\subsection{Connection to Typechecking}

A problem orthogonal to proof search but that could benefit
from the techniques and datastructures presented here is the
one of typechecking. In the coeffect calculus introduced by
Petricek, Orchard and Mycroft~\cite{petricek2014coeffects},
extra information is attached to the variables present in the
context. Their approach allows for writing derivations in
Bounded Linear Logic or building a program with an attached
dataflow analysis. However their deduction rules, when read
bottom-up, are suffering from some of the issues we highlighted
in this paper's introduction (having to guess how to partition
a context for instance). This may be tractable for Hindley-Milner-like
type systems enjoying type inference but we are interested in
more powerful type theories.

We believe that moving from their presentation to one with
input and output contexts as well as keeping more structured
contexts would give rise to a range of calculi whose judgements
are algorithmic in nature thus making them more amenable to
(bidirectional) typechecking. Our notion of variable annotation
also allows for slightly more subtle invariants being tracked:
the annotation's structure may depend on the structure of the
variable's type.

\section*{Special Thanks}

This paper was typeset thanks to Stevan Andjelkovic's work to make
compilation from literate agda to \LaTeX{} possible.
Ben Kavanagh was instrumental in pushing us to introduce a visual
representation of consumption annotations thus making the lump of
nested predicate definitions more accessible to the first time
reader.

\bibliographystyle{plain}
\bibliography{main}

\end{document}
