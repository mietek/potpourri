module linear.Usage where

open import Data.Nat as ℕ
open import Data.Fin
open import Data.Product
open import Data.Vec hiding ([_] ; _++_)
open import Function

open import linear.Type
open import linear.Scope as Sc
  hiding (Mergey ; copys
        ; Extending
        ; Weakening ; weakFin ; weakEnv
        ; Env ; Substituting
        ; Freshey ; module WithFreshVars)
open import linear.Context as C hiding (Mergey ; _⋈_ ; copys ; _++_ ; ++copys-elim)
open import Relation.Binary.PropositionalEquality

data Usage : (a : Type) → Set where
  [_] : (a : Type) → Usage a
  ]_[ : (a : Type) → Usage a

infixl 5 _∷_ -- _∙_
data Usages : {n : ℕ} (γ : Context n) → Set where
  []  : Usages []
  _∷_ : {n : ℕ} {γ : Context n} {a : Type} → Usage a → Usages γ → Usages (a ∷ γ)

infixr 4 _++_
_++_ : {m n : ℕ} {γ : Context m} {δ : Context n}
       (Γ : Usages γ) (Δ : Usages δ) → Usages (γ C.++ δ)
[]    ++ Δ = Δ
x ∷ Γ ++ Δ = x ∷ (Γ ++ Δ)

infix 1 _⊢_∈[_]⊠_
data _⊢_∈[_]⊠_ : {n : ℕ} {γ : Context n} (Γ : Usages γ) (k : Fin n) (a : Type) (Δ : Usages γ) → Set where
  z : {n : ℕ} {γ : Context n} {Γ : Usages γ} {a : Type} → [ a ] ∷ Γ ⊢ zero ∈[ a ]⊠ ] a [ ∷ Γ
  s_ : {n : ℕ} {γ : Context n} {k : Fin n} {Γ Δ : Usages γ} {a b : Type} {u : Usage b} →
       Γ ⊢ k ∈[ a ]⊠ Δ → u ∷ Γ ⊢ suc k ∈[ a ]⊠ u ∷ Δ

[[_]] : {m  : ℕ} (δ : Context m) → Usages δ
[[ δ ]] = induction Usages [] (λ a _ → [ a ] ∷_) δ

]]_[[ : {m : ℕ} (δ : Context m) → Usages δ
]] δ [[ = induction Usages [] (λ a _ → ] a [ ∷_) δ

data Mergey : {k l : ℕ} {m : Sc.Mergey k l} (M : C.Mergey m) → Set where
  finish : {k : ℕ} → Mergey (finish {k})
  copy   : {k l : ℕ} {m : Sc.Mergey k l} {M : C.Mergey m} (𝓜 : Mergey M) → Mergey (copy M)
  insert : {k l : ℕ} {m : Sc.Mergey k l} {M : C.Mergey m} {a : Type}
           (A : Usage a) (𝓜 : Mergey M) → Mergey (insert a M)

copys : (o : ℕ) {k l : ℕ} {m : Sc.Mergey k l} {M : C.Mergey m} → Mergey M → Mergey (C.copys o M)
copys zero    M = M
copys (suc o) M = copy (copys o M)

infixl 4 _⋈_
_⋈_ : {k l : ℕ} {γ : Context k} {m : Sc.Mergey k l} {M : C.Mergey m}
      (Γ : Usages γ) (𝓜 : Mergey M) → Usages (γ C.⋈ M)
Γ     ⋈ finish     = Γ
A ∷ Γ ⋈ copy M     = A ∷ (Γ ⋈ M)
Γ     ⋈ insert A M = A ∷ (Γ ⋈ M)

++copys-elim₂ :
  {k l o : ℕ} {m : Sc.Mergey k l} {M : C.Mergey m} {δ : Context o} {γ : Context k}
  (P : {γ : Context (o ℕ.+ l)} → Usages γ → Usages γ → Set)
  (Δ Δ′ : Usages δ) (Γ Γ′ : Usages γ) (𝓜 : Mergey M) →
  P ((Δ ++ Γ) ⋈ copys o 𝓜) ((Δ′ ++ Γ′) ⋈ copys o 𝓜) → P (Δ ++ (Γ ⋈ 𝓜)) (Δ′ ++ (Γ′ ⋈ 𝓜))
++copys-elim₂ P []      []        Γ Γ′ 𝓜 p = p
++copys-elim₂ P (A ∷ Δ) (A′ ∷ Δ′) Γ Γ′ 𝓜 p = ++copys-elim₂ (λ θ θ′ → P (A ∷ θ) (A′ ∷ θ′)) Δ Δ′ Γ Γ′ 𝓜 p


-- We can give an abstract interface to describe these relations
-- by introducing the notion of `Typing`. It exists for `Fin`,
-- `Check` and `Infer`:
Typing : (T : ℕ → Set) → Set₁
Typing T = {n : ℕ} {γ : Context n} (Γ : Usages γ) (t : T n) (σ : Type) (Δ : Usages γ) → Set

-- The notion of 'Usage Weakening' can be expressed for a `Typing`
-- of `T` if it enjoys `Scope Weakening`
Weakening : (T : ℕ → Set) (Wk : Sc.Weakening T) (𝓣 : Typing T) → Set
Weakening T Wk 𝓣 =
  {k l : ℕ} {γ : Context k} {Γ Δ : Usages γ} {m : Sc.Mergey k l} {M : C.Mergey m} {σ : Type}
  {t : T k} (𝓜 : Mergey M) → 𝓣 Γ t σ Δ → 𝓣 (Γ ⋈ 𝓜) (Wk m t) σ (Δ ⋈ 𝓜)

-- A first example of a Typing enjoying Usage Weakening: Fin.
TFin : Typing Fin
TFin = _⊢_∈[_]⊠_

weakFin : Weakening Fin Sc.weakFin TFin
weakFin finish        k    = k
weakFin (insert A 𝓜) k     = s (weakFin 𝓜 k)
weakFin (copy 𝓜)     z     = z
weakFin (copy 𝓜)     (s k) = s (weakFin 𝓜 k)


-- Similarly to 'Usage Weakening', the notion of 'Usage Substituting'
-- can be expressed for a `Typing` of `T` if it enjoys `Scope Substituting`

data Env {E : ℕ → Set} (𝓔 : Typing E) {l : ℕ} {θ : Context l} (T₁ : Usages θ) :
  {k : ℕ} (ρ : Sc.Env E l k) (Τ₂ : Usages θ) {γ : Context k} (Γ : Usages γ) → Set where
  []  : Env 𝓔 T₁ [] T₁ []
  _∷_ : {a : Type} {k : ℕ} {ρ : Sc.Env E l k} {t : E l} {Τ₂ Τ₃ : Usages θ} {γ : Context k} {Γ : Usages γ} →
        (T : 𝓔 T₁ t a Τ₂) (R : Env 𝓔 Τ₂ ρ Τ₃ Γ) → Env 𝓔 T₁ (t ∷ ρ) Τ₃ ([ a ] ∷ Γ)
  ─∷_ : {a : Type} {k : ℕ} {ρ : Sc.Env E l k} {t : E l} {Τ₂ : Usages θ} {γ : Context k} {Γ : Usages γ} →
        (R : Env 𝓔 T₁ ρ Τ₂ Γ) → Env 𝓔 T₁ (t ∷ ρ) Τ₂ (] a [ ∷ Γ)

weakEnv :
  {E : ℕ → Set} {𝓔 : Typing E} {Wk : Sc.Weakening E} (weakE : Weakening E Wk 𝓔) →
  {o : ℕ} {θ : Context o} (Τ : Usages θ) →
-- Basically `Weakening (flip (Sc.Env E) k) (Sc.weakEnv Wk) (λ Γ ρ _ Δ → Env 𝓔 Γ ρ Δ Τ)`
-- except that the fact that `Env` does not take a ̀Type` causes trouble...
  {k l : ℕ} {γ : Context k} {Γ Δ : Usages γ} {m : Sc.Mergey k l} {M : C.Mergey m}
  {ρ : Sc.Env E k o} (𝓜 : Mergey M) → Env 𝓔 Γ ρ Δ Τ → Env 𝓔 (Γ ⋈ 𝓜) (Sc.weakEnv Wk m ρ) (Δ ⋈ 𝓜) Τ
weakEnv weakE .[]     𝓜 []      = []
weakEnv weakE (_ ∷ Γ) 𝓜 (T ∷ ρ) = weakE 𝓜 T ∷ weakEnv weakE Γ 𝓜 ρ
weakEnv weakE (_ ∷ Γ) 𝓜 (─∷ ρ)  = ─∷ weakEnv weakE Γ 𝓜 ρ

Substituting : (E T : ℕ → Set) ([_]_ : Sc.Substituting E T) (𝓔 : Typing E) (𝓣 : Typing T) → Set
Substituting E T subst 𝓔 𝓣 =
  {k l : ℕ} {γ : Context k} {Γ Δ : Usages γ} {σ : Type} {t : T k} {ρ : Sc.Env E l k}
  {θ : Context l} {Τ₁ Τ₂ : Usages θ} →
  Env 𝓔 Τ₁ ρ Τ₂ Γ → 𝓣 Γ t σ Δ → ∃ λ Τ₃ → 𝓣 Τ₁ (subst ρ t) σ Τ₃ × Env 𝓔 Τ₃ ρ Τ₂ Δ

Extending : (E : ℕ → ℕ → Set) (Ext : Sc.Extending E) (𝓔 : {l : ℕ} {θ : Context l} (T₁ : Usages θ) {k : ℕ} (ρ : E l k) (Τ₂ : Usages θ) {γ : Context k} (Γ : Usages γ) → Set) → Set
Extending E Ext 𝓔 =
  {k l o : ℕ} {θ : Context l} {Τ₁ Τ₂ : Usages θ} (δ : Context o) {e : E l k} {γ : Context k} {Γ : Usages γ} →
  𝓔 Τ₁ e Τ₂ Γ → 𝓔 ([[ δ ]] ++ Τ₁) (Ext o e) (]] δ [[ ++ Τ₂) ([[ δ ]] ++ Γ)

record Freshey (E : ℕ → Set) (F : Sc.Freshey E) (𝓔 : Typing E) : Set where
  field
    fresh : {k : ℕ} {γ : Context k} {Γ : Usages γ} (σ : Type) →
            𝓔 ([ σ ] ∷ Γ) (Sc.Freshey.fresh F {k}) σ (] σ [ ∷ Γ)
    weak  : Weakening E (Sc.Freshey.weak F) 𝓔

module WithFreshVars {E : ℕ → Set} {F : Sc.Freshey E} {𝓔 : Typing E} (𝓕 : Freshey E F 𝓔) where

  module ScF   = Sc.Freshey F
  module ScWFV = Sc.WithFreshVars F

  withFreshVars : Extending (Sc.Env E) ScWFV.withFreshVars (Env 𝓔)
  withFreshVars []      ρ = ρ
  withFreshVars (a ∷ δ) ρ = fresh a ∷ weakEnv weak _ (insert ] a [ finish) (withFreshVars δ ρ)
    where open Freshey 𝓕

  withFreshVar : {k o : ℕ} {γ : Context k} {Γ Δ : Usages γ} {θ : Context o} {Τ : Usages θ} {ρ : Sc.Env E k o} 
                 (a : Type) → Env 𝓔 Γ ρ Δ Τ → Env 𝓔 ([ a ] ∷ Γ) (ScWFV.withFreshVar ρ) (] a [ ∷ Δ) ([ a ] ∷ Τ)
  withFreshVar a = withFreshVars (a ∷ [])
