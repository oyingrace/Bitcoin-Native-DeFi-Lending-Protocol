;; title: governance-treasury
;; version: 1.0.0
;; summary: DAO-controlled treasury
;; description: Treasury managed by governance votes - Clarity 4

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u4500))
(define-constant ERR-INSUFFICIENT-FUNDS (err u4501))

;; Data Variables
(define-data-var treasury-balance uint u0)
(define-data-var total-spent uint u0)

;; Data Maps - Using stacks-block-time for Clarity 4
(define-map spending-records uint {
  recipient: principal,
  amount: uint,
  purpose: (string-ascii 100),
  spent-at: uint  ;; Clarity 4: Unix timestamp
})