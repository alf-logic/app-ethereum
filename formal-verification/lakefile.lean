import Lake
open Lake DSL

package FormalVerification where
  leanOptions := #[
    ⟨`autoImplicit, false⟩
  ]

@[default_target]
lean_lib FormalVerification
