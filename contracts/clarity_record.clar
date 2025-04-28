;; Clarity Blockchain Record System
;; Immutable and transparent record keeping for land titles and property documents. System-wide document counter

(define-data-var document-count uint u0)

;; Core Storage Structures
(define-map title-documents
  { doc-id: uint }
  {
    title-name: (string-ascii 64),
    title-owner: principal,
    document-size: uint,
    registration-block: uint,
    property-description: (string-ascii 128),
    tags: (list 10 (string-ascii 32))
  }
)

(define-map viewer-permissions
  { doc-id: uint, viewer: principal }
  { access-allowed: bool }
)

;; Error Response Constants
(define-constant error-document-not-found (err u301))
(define-constant error-invalid-size (err u304))
(define-constant error-permission-denied (err u305))
(define-constant error-not-owner (err u306))
(define-constant error-admin-only (err u300))
(define-constant error-viewing-restricted (err u307))
(define-constant error-document-already-exists (err u302))
(define-constant error-invalid-name (err u303))
