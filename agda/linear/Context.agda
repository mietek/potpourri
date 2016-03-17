module linear.Context where

open import Data.Nat
open import Data.Fin
open import Data.Vec hiding (_++_)

open import linear.Type

Context : ℕ → Set
Context = Vec Type

-- Contexts with one hole. Rather than representing them as
-- Contexts (with ε playing the role of the hole), we opt
-- for a different representation with explicit composition
-- which allows us to get rid of the green slime that would
-- be introduced by using `_++_`

infixl 5 _∷_ _∙_
data Holey (m : ℕ) : ℕ → Set where
  []  : Holey m m
  _∷_ : {n : ℕ} (a : Type) (Γ : Holey m n) → Holey m (suc n)
  _∙_ : {n o : ℕ} (Γ : Holey m n) (Δ : Holey n o) → Holey m o

-- Given a Holey context, we can plug the hole using another
-- context.

infixr 3 _⇐_
_⇐_ : {m n : ℕ} (h : Holey m n) (Γ : Context m) → Context n
[]    ⇐ Γ = Γ
a ∷ h ⇐ Γ = a ∷ (h ⇐ Γ)
g ∙ h ⇐ Γ = h ⇐ (g ⇐ Γ)

-- Induction principle
induction :
  (P : {n : ℕ} → Context n → Set)
  (pε : P [])
  (p∷ : {n : ℕ} (a : Type) (Γ : Context n) → P Γ → P (a ∷ Γ)) →
  {n : ℕ} (Γ : Context n) → P Γ
induction P pε p∷ []      = pε
induction P pε p∷ (a ∷ Γ) = p∷ a Γ (induction P pε p∷ Γ)
