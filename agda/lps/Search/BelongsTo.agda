import lps.IMLL                  as IMLL
import lps.Linearity             as Linearity
import lps.Linearity.Consumption as Consumption

open import Data.Product hiding (map)
open import Data.Nat as ℕ
open import Function

import lib.Context as Con
open import lib.Maybe
open import lib.Nullary

open import Relation.Nullary
open import Relation.Binary.PropositionalEquality as Eq using (_≡_)

module lps.Search.BelongsTo where

  module Type where

    open Con.Context
    open IMLL.Type

    module Cover where

      open Linearity.Type

      module FromFree where

        infix 4 _∈[_]▸_
        data _∈[_]▸_ (k : ℕ) : (σ : ty) (S : Cover σ) → Set where
          `κ    : k ∈[ `κ k ]▸ `κ k
          _`&ˡ_ : {σ : ty} {S : Cover σ} (prS : k ∈[ σ ]▸ S) (τ : ty) →
                  k ∈[ σ `& τ ]▸ S `&[ τ ]
          _`&ʳ_ : (σ : ty) {τ : ty} {T : Cover τ} (prT : k ∈[ τ ]▸ T) →
                  k ∈[ σ `& τ ]▸ [ σ ]`& T
          _`⊗ˡ_ : {σ : ty} {S : Cover σ} (prS : k ∈[ σ ]▸ S) (τ : ty) →
                  k ∈[ σ `⊗ τ ]▸ S `⊗[ τ ]
          _`⊗ʳ_ : (σ : ty) {τ : ty} {T : Cover τ} (prT : k ∈[ τ ]▸ T) →
                  k ∈[ σ `⊗ τ ]▸ [ σ ]`⊗ T

        infix 4 [_]∋_∈_
        [_]∋_∈_ : (σ : ty) (k : ℕ) (T : Cover σ) → Set
        [ σ ]∋ k ∈ τ = k ∈[ σ ]▸ τ

        ∈κ : ∀ k {l} → k ≡ l → Σ[ C ∈ Cover $ `κ l ] [ `κ l ]∋ k ∈ C
        ∈κ k Eq.refl = `κ k , `κ

        ∈[&]ˡ : ∀ {k σ} (τ : ty) → Σ[ S ∈ Cover σ ] [ σ ]∋ k ∈ S →
                Σ[ ST ∈ Cover $ σ `& τ ] [ σ `& τ ]∋ k ∈ ST
        ∈[&]ˡ τ (S , prS) = S `&[ τ ] , prS `&ˡ τ

        ∈[&]ʳ : ∀ {k τ} (σ : ty) → Σ[ T ∈ Cover τ ] [ τ ]∋ k ∈ T →
                Σ[ ST ∈ Cover $ σ `& τ ] [ σ `& τ ]∋ k ∈ ST
        ∈[&]ʳ σ (T , prT) = [ σ ]`& T , σ `&ʳ prT

        ∈[⊗]ˡ : ∀ {k σ} (τ : ty) → Σ[ S ∈ Cover σ ] [ σ ]∋ k ∈ S →
                Σ[ ST ∈ Cover $ σ `⊗ τ ] [ σ `⊗ τ ]∋ k ∈ ST
        ∈[⊗]ˡ τ (S , prS) = S `⊗[ τ ] , prS `⊗ˡ τ

        ∈[⊗]ʳ : ∀ {k τ} (σ : ty) → Σ[ T ∈ Cover τ ] [ τ ]∋ k ∈ T →
                Σ[ ST ∈ Cover $ σ `⊗ τ ] [ σ `⊗ τ ]∋ k ∈ ST
        ∈[⊗]ʳ σ (T , prT) = [ σ ]`⊗ T , σ `⊗ʳ prT


        open Context
        infix 6 _∈?[_]
        _∈?[_] : (k : ℕ) (σ : ty) → Con (Σ[ S′ ∈ Cover σ ] [ σ ]∋ k ∈ S′)
        k ∈?[ `κ l   ] = dec (k ≟ l) (return ∘ ∈κ k) (const ε)
        k ∈?[ σ `⊗ τ ] = map (∈[⊗]ˡ τ) (k ∈?[ σ ]) ++ map (∈[⊗]ʳ σ) (k ∈?[ τ ])
        k ∈?[ σ `& τ ] = map (∈[&]ˡ τ) (k ∈?[ σ ]) ++ map (∈[&]ʳ σ) (k ∈?[ τ ])

        open IMLL
        open Linearity.LTC
        ⟦_⟧ : {σ : ty} {k : ℕ} {T : Cover σ} (pr : [ σ ]∋ k ∈ T) → ｢ T ｣ ⊢ `κ k
        ⟦ `κ       ⟧ = `v
        ⟦ pr `&ˡ τ ⟧ = ⟦ pr ⟧
        ⟦ σ `&ʳ pr ⟧ = ⟦ pr ⟧
        ⟦ pr `⊗ˡ τ ⟧ = ⟦ pr ⟧
        ⟦ σ `⊗ʳ pr ⟧ = ⟦ pr ⟧

      module FromDented where

        open FromFree hiding (⟦_⟧)

        infix 4 _∈_▸_
        data _∈_▸_ (k : ℕ) : {σ : ty} (S : Cover σ) (T : Cover σ) → Set where
          _`⊗ˡ_   : {σ : ty} {S S′ : Cover σ} (s : k ∈ S ▸ S′)
                    {τ : ty} (T : Cover τ) → k ∈ S `⊗ T ▸ S′ `⊗ T
          _`⊗ʳ_   : {σ : ty} (S : Cover σ) {τ : ty} {T T′ : Cover τ}
                    (t : k ∈ T ▸ T′) → k ∈ S `⊗ T ▸ S `⊗ T′
          [_]`⊗_  : (σ : ty) {τ : ty} {T T′ : Cover τ} (t : k ∈ T ▸ T′) →
                    k ∈ [ σ ]`⊗ T ▸ [ σ ]`⊗ T′
          _`⊗ʳ[_] : {σ : ty} (S : Cover σ) {τ : ty} {T : Cover τ}
                    (prT : k ∈[ τ ]▸ T) → k ∈ S `⊗[ τ ] ▸ S `⊗ T
          [_]`⊗ˡ_ : {σ : ty} {S : Cover σ} (prS : k ∈[ σ ]▸ S)
                    {τ : ty} (T : Cover τ)  → k ∈ [ σ ]`⊗ T ▸ S `⊗ T
          _`⊗[_]  : {σ : ty} {S S′ : Cover σ} (s : k ∈ S ▸ S′) (τ : ty) →
                    k ∈ S `⊗[ τ ] ▸ S′ `⊗[ τ ]
          _`&ˡ_   : ∀ {σ} {S S′ : Cover σ} (s : k ∈ S ▸ S′) τ →
                    k ∈ S `&[ τ ] ▸ S′ `&[ τ ]
          _`&ʳ_   : ∀ σ {τ} {T T′ : Cover τ} (t : k ∈ T ▸ T′) →
                    k ∈ [ σ ]`& T ▸ [ σ ]`& T′

        infix 4 _∋_∈_
        _∋_∈_ : {σ : ty} (S : Cover σ) (k : ℕ) (T : Cover σ) → Set
        σ ∋ k ∈ τ = k ∈ σ ▸ τ

        ∈⊗ˡ : ∀ {k a b} {A : Cover a} (B : Cover b) →
              Σ[ A′ ∈ Cover a ] A ∋ k ∈ A′ →
              Σ[ AB ∈ Cover $ a `⊗ b ] A `⊗ B ∋ k ∈ AB
        ∈⊗ˡ B (A′ , prA) = A′ `⊗ B , prA `⊗ˡ B
  
        ∈⊗ʳ : ∀ {k a b} (A : Cover a) {B : Cover b} →
              Σ[ B′ ∈ Cover b ] B ∋ k ∈ B′ →
              Σ[ AB ∈ Cover $ a `⊗ b ] A `⊗ B ∋ k ∈ AB
        ∈⊗ʳ A (B′ , prB) = A `⊗ B′ , A `⊗ʳ prB

        ∈[]⊗ : ∀ {k : ℕ} {b : ty} {B : Cover b} (a : ty) →
               Σ[ B′ ∈ Cover b ] B ∋ k ∈ B′ →
               Σ[ AB ∈ Cover $ a `⊗ b ] [ a ]`⊗ B ∋ k ∈ AB
        ∈[]⊗ a (B′ , prB) = [ a ]`⊗ B′ , [ a ]`⊗ prB

        ∈[]⊗ˡ : ∀ {k : ℕ} {b : ty} (B : Cover b) {a : ty} →
                Σ[ A ∈ Cover a ] [ a ]∋ k ∈ A →
                Σ[ AB ∈ Cover $ a `⊗ b ] [ a ]`⊗ B ∋ k ∈ AB
        ∈[]⊗ˡ B (A , prA) = A `⊗ B , [ prA ]`⊗ˡ B

        ∈⊗[] : ∀ {k : ℕ} {a : ty} {A : Cover a} (b : ty) →
               Σ[ A′ ∈ Cover a ] A ∋ k ∈ A′ →
               Σ[ AB ∈ Cover $ a `⊗ b ] A `⊗[ b ] ∋ k ∈ AB
        ∈⊗[] b (A′ , prA) = A′ `⊗[ b ] , prA `⊗[ b ]

        ∈⊗[]ʳ : ∀ {k : ℕ} {a : ty} (A : Cover a) {b : ty} →
                Σ[ B ∈ Cover b ] [ b ]∋ k ∈ B →
                Σ[ AB ∈ Cover $ a `⊗ b ] A `⊗[ b ] ∋ k ∈ AB
        ∈⊗[]ʳ A (B , prB) = A `⊗ B , A `⊗ʳ[ prB ]
  
        ∈[]& : ∀ {k : ℕ} {b : ty} {B : Cover b} (a : ty) →
               Σ[ B′ ∈ Cover b ] B ∋ k ∈ B′ →
               Σ[ AB ∈ Cover $ a `& b ] [ a ]`& B ∋ k ∈ AB
        ∈[]& a (B′ , prB) = [ a ]`& B′ , a `&ʳ prB

        ∈&[] : ∀ {k : ℕ} {a : ty} {A : Cover a} (b : ty) →
               Σ[ A′ ∈ Cover a ] A ∋ k ∈ A′ →
               Σ[ AB ∈ Cover $ a `& b ] A `&[ b ] ∋ k ∈ AB
        ∈&[] b (A′ , prA) = A′ `&[ b ] , prA `&ˡ b
        open Context

        infix 6 _∈?_
        _∈?_ : (k : ℕ) {σ : ty} (S : Cover σ) → Con (Σ[ S′ ∈ Cover σ ] S ∋ k ∈ S′)
        k ∈? `κ l      = ε
        k ∈? A `⊗ B    = map (∈⊗ˡ B) (k ∈? A) ++ map (∈⊗ʳ A) (k ∈? B)
        k ∈? [ a ]`⊗ B = map (∈[]⊗ˡ B) (k ∈?[ a ]) ++ map (∈[]⊗ a) (k ∈? B)
        k ∈? A `⊗[ b ] = map (∈⊗[] b) (k ∈? A) ++ map (∈⊗[]ʳ A) (k ∈?[ b ])
        k ∈? a `& b    = ε
        k ∈? A `&[ b ] = map (∈&[] b) (k ∈? A)
        k ∈? [ a ]`& B = map (∈[]& a) (k ∈? B)

        open IMLL
        open Linearity.LTC
        open Consumption.LCT.Cover

        ⟦⊗ˡ⟧ : ∀ {σ k} τ {S₁ S₂ : Cover σ} (T : Cover τ) →
               Σ[ S ∈ Cover σ ] S₂ ≡ S₁ ─ S × ｢ S ｣ ⊢ `κ k →
               Σ[ ST ∈ Cover $ σ `⊗ τ ] S₂ `⊗ T ≡ S₁ `⊗ T ─ ST × ｢ ST ｣ ⊢ `κ k
        ⟦⊗ˡ⟧ τ T (S , diff , tm) = S `⊗[ τ ] , diff `⊗ˡ T , tm

        ⟦⊗ʳ⟧ : ∀ σ {τ k} (S : Cover σ) {T₁ T₂ : Cover τ} →
               Σ[ T ∈ Cover τ ] T₂ ≡ T₁ ─ T × ｢ T ｣ ⊢ `κ k →
               Σ[ ST ∈ Cover $ σ `⊗ τ ] S `⊗ T₂ ≡ S `⊗ T₁ ─ ST × ｢ ST ｣ ⊢ `κ k
        ⟦⊗ʳ⟧ σ S (T , diff , tm) = [ σ ]`⊗ T , S `⊗ʳ diff , tm

        ⟦⊗[]⟧ : ∀ {σ k} τ {S₁ S₂ : Cover σ} →
               Σ[ S ∈ Cover σ ] S₂ ≡ S₁ ─ S × ｢ S ｣ ⊢ `κ k →
               Σ[ ST ∈ Cover $ σ `⊗ τ ] S₂ `⊗[ τ ] ≡ S₁ `⊗[ τ ] ─ ST × ｢ ST ｣ ⊢ `κ k
        ⟦⊗[]⟧ τ (S , diff , tm) = S `⊗[ τ ] , diff `⊗[ τ ] , tm

        ⟦[]⊗⟧ : ∀ σ {τ k} {T₁ T₂ : Cover τ} →
               Σ[ T ∈ Cover τ ] T₂ ≡ T₁ ─ T × ｢ T ｣ ⊢ `κ k →
               Σ[ ST ∈ Cover $ σ `⊗ τ ] [ σ ]`⊗ T₂ ≡ [ σ ]`⊗ T₁ ─ ST × ｢ ST ｣ ⊢ `κ k
        ⟦[]⊗⟧ σ (T , diff , tm) = [ σ ]`⊗ T , [ σ ]`⊗ diff , tm

        ⟦&ˡ⟧ : ∀ {σ} {S₁ S₂ : Cover σ} τ {k} →
              Σ[ S ∈ Cover σ ] S₂ ≡ S₁ ─ S × ｢ S ｣ ⊢ `κ k →
              Σ[ ST ∈ Cover $ σ `& τ ] S₂ `&[ τ ] ≡ S₁ `&[ τ ] ─ ST × ｢ ST ｣ ⊢ `κ k
        ⟦&ˡ⟧ τ {k} (S , diff , tm) = S `&[ τ ] , diff `&[ τ ] , tm
 
        ⟦&ʳ⟧ : ∀ σ {τ} {T₁ T₂ : Cover τ} {k} →
              Σ[ T ∈ Cover τ ] T₂ ≡ T₁ ─ T × ｢ T ｣ ⊢ `κ k →
              Σ[ ST ∈ Cover $ σ `& τ ] [ σ ]`& T₂ ≡ [ σ ]`& T₁ ─ ST × ｢ ST ｣ ⊢ `κ k
        ⟦&ʳ⟧ σ (T , diff , tm) = [ σ ]`& T , [ σ ]`& diff , tm

        ⟦⊗ʳ[]⟧ : ∀ {k} σ {τ} (S : Cover σ) {T : Cover τ} →
                Σ[ E ∈ Cover τ ] T ≡[ τ ]─ E × ｢ E ｣ ⊢ `κ k → 
                Σ[ ST ∈ Cover $ σ `⊗ τ ] S `⊗ T ≡ S `⊗[ τ ] ─ ST × ｢ ST ｣ ⊢ `κ k
        ⟦⊗ʳ[]⟧ σ S (E , diff , tm) = [ σ ]`⊗ E , S `⊗ʳ[ diff ] , tm

        ⟦⊗ˡ[]⟧ : ∀ {k} {σ} τ {S : Cover σ} (T : Cover τ) →
                Σ[ E ∈ Cover σ ] S ≡[ σ ]─ E × ｢ E ｣ ⊢ `κ k → 
                Σ[ ST ∈ Cover $ σ `⊗ τ ] S `⊗ T ≡ [ σ ]`⊗ T ─ ST × ｢ ST ｣ ⊢ `κ k
        ⟦⊗ˡ[]⟧ τ T (E , diff , tm) = E `⊗[ τ ] , [ diff ]`⊗ˡ T , tm

        ⟦_⟧ : {σ : ty} {S : Cover σ} {k : ℕ} {T : Cover σ} (pr : S ∋ k ∈ T) →
              Σ[ E ∈ Cover σ ] T ≡ S ─ E × ｢ E ｣ ⊢ `κ k
        ⟦ pr `⊗ˡ T     ⟧ = ⟦⊗ˡ⟧ _ _ ⟦ pr ⟧
        ⟦ S `⊗ʳ pr     ⟧ = ⟦⊗ʳ⟧ _ _ ⟦ pr ⟧
        ⟦ [ σ ]`⊗ pr   ⟧ = ⟦[]⊗⟧ _ ⟦ pr ⟧
        ⟦ S `⊗ʳ[ prT ] ⟧ = ⟦⊗ʳ[]⟧ _ S $ _ , inj[ _ ] , FromFree.⟦ prT ⟧
        ⟦ [ prS ]`⊗ˡ T ⟧ = ⟦⊗ˡ[]⟧ _ T $ _ , inj[ _ ] , FromFree.⟦ prS ⟧
        ⟦ pr `⊗[ τ ]   ⟧ = ⟦⊗[]⟧ _ ⟦ pr ⟧
        ⟦ pr `&ˡ τ     ⟧ = ⟦&ˡ⟧ _ ⟦ pr ⟧
        ⟦ σ `&ʳ pr     ⟧ = ⟦&ʳ⟧ _ ⟦ pr ⟧

    module Usage where

      open Cover
      open Linearity.Type

      infix 4 _∈_▸_
      data _∈_▸_ (k : ℕ) : {σ : ty} (S : Usage σ) (T : Usage σ) → Set where
        [_] : {σ : ty} {S : Cover σ} (prS : FromFree.[ σ ]∋ k ∈ S) →
              k ∈ [ σ ] ▸ ] S [
        ]_[ : {σ : ty} {S S′ : Cover σ} (prS : S FromDented.∋ k ∈ S′) →
              k ∈ ] S [ ▸ ] S′ [

      infix 4 _∋_∈_
      _∋_∈_ : {σ : ty} (S : Usage σ) (k : ℕ) (T : Usage σ) → Set
      σ ∋ k ∈ τ = k ∈ σ ▸ τ

      open Context

      [∈] : ∀ {k σ} → Σ[ S ∈ Cover σ ] FromFree.[ σ ]∋ k ∈ S →
            Σ[ S ∈ Usage σ ] [ σ ] ∋ k ∈ S
      [∈] (S , prS) = ] S [ , [ prS ]

      ]∈[ : ∀ {k σ} {S : Cover σ} → Σ[ S′ ∈ Cover σ ] S FromDented.∋ k ∈ S′ →
            Σ[ S′ ∈ Usage σ ] ] S [ ∋ k ∈ S′
      ]∈[ (S , prS) = ] S [ , ] prS [

      infix 6 _∈?_
      _∈?_ : (k : ℕ) {σ : ty} (S : Usage σ) → Con (Σ[ S′ ∈ Usage σ ] S ∋ k ∈ S′)
      k ∈? [ σ ] = map [∈] $ k FromFree.∈?[ σ ]
      k ∈? ] S [ = map ]∈[ $ k FromDented.∈? S

      module Soundness where

        open IMLL
        open Consumption
        open LCT.Usage
        open Linearity.Type.Cover
        open Linearity.Type.Usage
  
        ⟦][⟧ : {σ : ty} {S : Cover σ} {k : ℕ} {T : Cover σ} →
               Σ[ E ∈ Cover σ ] T LCT.Cover.≡ S ─ E × Cover.｢ E ｣ ⊢ `κ k →
               Σ[ E ∈ Usage σ ] ] T [ ≡ ] S [ ─ E × Usage.｢ E ｣ ⊢ `κ k
        ⟦][⟧ (E , diff , tm) = ] E [ , ] diff [ , tm

        ⟦_⟧ : {σ : ty} {S : Usage σ} {k : ℕ} {T : Usage σ} (pr : S ∋ k ∈ T) →
              Σ[ E ∈ Usage σ ] T ≡ S ─ E × Usage.｢ E ｣ ⊢ `κ k
        ⟦ [ prS ] ⟧ = _ , inj[ _ ] , FromFree.⟦ prS ⟧
        ⟦ ] prS [ ⟧ = ⟦][⟧ FromDented.⟦ prS ⟧

  module Context where

    module SBT = Type
    open IMLL.Type
    open Con.Context
    open Linearity
    open Linearity.Context
    open Pointwise
    open Con.Context.Context

    infix 4 _∈_▸_ 
    data _∈_▸_ (k : ℕ) : {γ : Con ty} (Γ Δ : Usage γ) → Set where
      zro : ∀ {γ σ} {Γ : Usage γ} {S S′ : LT.Usage σ} →
            S Type.Usage.∋ k ∈ S′ → k ∈ Γ ∙ S ▸ Γ ∙ S′
      suc : ∀ {γ τ} {Γ Γ′ : Usage γ} {T : LT.Usage τ} →
            k ∈ Γ ▸ Γ′ → k ∈ Γ ∙ T ▸ Γ′ ∙ T

    infix 4 _∋_∈_ 
    _∋_∈_ : {γ : Con ty} (Γ : Usage γ) (k : ℕ) (Δ : Usage γ) → Set
    Γ ∋ k ∈ Δ = k ∈ Γ ▸ Δ

    ∈zro : ∀ {γ σ} (Γ : Usage γ) {S : LT.Usage σ} {k} →
           Σ[ S′ ∈ LT.Usage σ ] S Type.Usage.∋ k ∈ S′ →
           Σ[ Γ′ ∈ Usage $ γ ∙ σ ] Γ ∙ S ∋ k ∈ Γ′
    ∈zro Γ (S , prS) = Γ ∙ S , zro prS

    ∈suc : ∀ {γ σ} {Γ : Usage γ} (S : LT.Usage σ) {k} →
           Σ[ Γ′ ∈ Usage γ ] Γ ∋ k ∈ Γ′ →
           Σ[ Γ′ ∈ Usage $ γ ∙ σ ] Γ ∙ S ∋ k ∈ Γ′
    ∈suc S (Γ′ , prΓ) = Γ′ ∙ S , suc prΓ


    _∈?_ : (k : ℕ) {γ : Con ty} (Γ : Usage γ) → Con (Σ[ Γ′ ∈ Usage γ ] Γ ∋ k ∈ Γ′)
    k ∈? ε       = ε
    k ∈? (Γ ∙ S) = map (∈suc S) (k ∈? Γ) ++ map (∈zro Γ) (k Type.Usage.∈? S)
      where open Con.Context.Context

    module Soundness where

      open IMLL
      open Linearity
      open Consumption
      open Consumption.Context

      ⟦zro⟧ : (γ : Con ty) (Γ : Usage γ) {σ : ty} {S S′ : LT.Usage σ} (k : ℕ) →
              Σ[ T ∈ LT.Usage σ ] S′ LCT.Usage.≡ S ─ T × LTU.｢ T ｣ ⊢ `κ k →
              Σ[ E ∈ Usage $ γ ∙ σ ] Γ ∙ S′ ≡ Γ ∙ S ─ E × ｢ E ｣ ⊢ `κ k
      ⟦zro⟧ γ Γ k (T , diff , tm) =
        let eq = Eq.trans (Eq.cong (flip _++_ LTU.｢ T ｣) ｢inj[ γ ]｣) $ ε++ LTU.｢ T ｣
        in LC.inj[ γ ] ∙ T
         , LCC.inj[ Γ ] ∙ diff
         , Eq.subst (flip _⊢_ (`κ k)) (Eq.sym eq) tm

      ⟦suc⟧ : {γ : Con ty} {Γ Δ : Usage γ} (σ : ty) {S : LT.Usage σ} {k : ℕ} →
              Σ[ E ∈ Usage γ ] Δ ≡ Γ ─ E × ｢ E ｣ ⊢ `κ k →
              Σ[ E ∈ Usage $ γ ∙ σ ] Δ ∙ S ≡ Γ ∙ S ─ E × ｢ E ｣ ⊢ `κ k
      ⟦suc⟧ σ (E , diff , tm) = E ∙ LT.[ σ ] , diff ∙ LCT.Usage.`id , tm

      ⟦_⟧ : {γ : Con ty} {Γ : Usage γ} {k : ℕ} {Δ : Usage γ} (pr : Γ ∋ k ∈ Δ) →
            Σ[ E ∈ Usage γ ] Δ ≡ Γ ─ E × ｢ E ｣ ⊢ `κ k
      ⟦ zro x  ⟧ = ⟦zro⟧ _ _ _ SBT.Usage.Soundness.⟦ x ⟧
      ⟦ suc pr ⟧ = ⟦suc⟧ _ ⟦ pr ⟧