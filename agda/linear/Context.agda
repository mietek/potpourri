module linear.Context where

open import Data.Nat as ℕ
open import Data.Fin
open import Data.Vec hiding (_++_)

open import linear.Type
open import linear.Scope as Sc hiding (Mergey ; copys)

Context : ℕ → Set
Context = Vec Type

-- Induction principle
induction :
  (P : {n : ℕ} → Context n → Set)
  (pε : P [])
  (p∷ : {n : ℕ} (a : Type) (Γ : Context n) → P Γ → P (a ∷ Γ)) →
  {n : ℕ} (Γ : Context n) → P Γ
induction P pε p∷ []      = pε
induction P pε p∷ (a ∷ Γ) = p∷ a Γ (induction P pε p∷ Γ)

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

_++ : {m n : ℕ} (δ : Context n) → Holey m (n ℕ.+ m)
δ ++ = induction (λ {n} _ → Holey _ (n ℕ.+ _)) [] (λ a _ → a ∷_) δ

infixr 4 _⇐_
_⇐_ : {m n : ℕ} (h : Holey m n) (Γ : Context m) → Context n
[]    ⇐ Γ = Γ
a ∷ h ⇐ Γ = a ∷ (h ⇐ Γ)
g ∙ h ⇐ Γ = h ⇐ (g ⇐ Γ)

data Mergey : {k l : ℕ} (m : Sc.Mergey k l) → Set where
  finish : {k : ℕ} → Mergey (finish {k})
  copy   : {k l : ℕ} {m : Sc.Mergey k l} → Mergey m → Mergey (copy m)
  insert : {k l : ℕ} {m : Sc.Mergey k l} → Type → Mergey m → Mergey (insert m)

copys : (o : ℕ) {k l : ℕ} {m : Sc.Mergey k l} (M : Mergey m) → Mergey (Sc.copys o m)
copys zero    M = M
copys (suc o) M = copy (copys o M)

infixl 4 _⋈_
_⋈_ : {k l : ℕ} (Γ : Context k) {m : Sc.Mergey k l} (M : Mergey m) → Context l
Γ     ⋈ finish     = Γ
a ∷ Γ ⋈ copy M     = a ∷ (Γ ⋈ M)
Γ     ⋈ insert a M = a ∷ (Γ ⋈ M)
