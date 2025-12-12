;; Lending Pool Trait
;; Standard interface for lending pool implementations

(define-trait lending-pool-trait
    (
        ;; Deposit assets into the pool
        (deposit (uint) (response bool uint))
        
        ;; Withdraw assets from the pool
        (withdraw (uint) (response bool uint))
        
        ;; Borrow against collateral
        (borrow (uint) (response bool uint))
        
        ;; Repay borrowed amount
        (repay (uint) (response bool uint))
        
        ;; Get user's collateral balance
        (get-collateral (principal) (response uint uint))
        
        ;; Get user's debt balance
        (get-debt (principal) (response uint uint))
        
        ;; Get current interest rate
        (get-interest-rate () (response uint uint))
    )
)
