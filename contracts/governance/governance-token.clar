;; title: governance-token
;; version: 1.0.0
;; summary: ChainChat governance token
;; description: SIP-010 fungible token for governance - Clarity 4

;; Implement SIP-010 trait

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u4000))
(define-constant ERR-NOT-TOKEN-OWNER (err u4001))
(define-constant ERR-INSUFFICIENT-BALANCE (err u4002))