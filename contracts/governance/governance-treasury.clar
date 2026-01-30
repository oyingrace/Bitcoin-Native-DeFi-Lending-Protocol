;; title: governance-treasury
;; version: 1.0.0
;; summary: DAO-controlled treasury
;; description: Treasury managed by governance votes - Clarity 4

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u4500))
(define-constant ERR-INSUFFICIENT-FUNDS (err u4501))