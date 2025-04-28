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
(define-constant error-invalid-tags (err u308))

;; Admin Configuration
(define-constant registry-admin tx-sender)

;; ===== Helper Functions for Validation and Access Control =====

;; Check if document exists in registry
(define-private (document-exists? (doc-id uint))
  (is-some (map-get? title-documents { doc-id: doc-id }))
)

;; Verify if specified principal is document owner
(define-private (check-ownership (doc-id uint) (user principal))
  (match (map-get? title-documents { doc-id: doc-id })
    document (is-eq (get title-owner document) user)
    false
  )
)

;; Get document size in bytes
(define-private (get-document-size (doc-id uint))
  (default-to u0
    (get document-size
      (map-get? title-documents { doc-id: doc-id })
    )
  )
)

;; Validate individual tag format
(define-private (validate-tag (tag (string-ascii 32)))
  (and
    (> (len tag) u0)
    (< (len tag) u33)
  )
)

;; Ensure all tags meet requirements
(define-private (validate-tags (tag-list (list 10 (string-ascii 32))))
  (and
    (> (len tag-list) u0)
    (<= (len tag-list) u10)
    (is-eq (len (filter validate-tag tag-list)) (len tag-list))
  )
)

;; ===== Public Document Management Functions =====


;; Delete a document from registry
(define-public (delete-document (doc-id uint))
  (let
    (
      (doc-info (unwrap! (map-get? title-documents { doc-id: doc-id })
        error-document-not-found))
    )
    ;; Ownership verification
    (asserts! (document-exists? doc-id) error-document-not-found)
    (asserts! (is-eq (get title-owner doc-info) tx-sender) error-not-owner)

    ;; Remove document
    (map-delete title-documents { doc-id: doc-id })
    (ok true)
  )
)

;; Transfer document ownership to another entity
(define-public (transfer-document (doc-id uint) (new-owner principal))
  (let
    (
      (doc-info (unwrap! (map-get? title-documents { doc-id: doc-id })
        error-document-not-found))
    )
    ;; Verify caller is the current owner
    (asserts! (document-exists? doc-id) error-document-not-found)
    (asserts! (is-eq (get title-owner doc-info) tx-sender) error-not-owner)

    ;; Update ownership record
    (map-set title-documents
      { doc-id: doc-id }
      (merge doc-info { title-owner: new-owner })
    )
    (ok true)
  )
)

;; Register a new land title document
(define-public (register-document
  (title (string-ascii 64))
  (file-size uint)
  (description (string-ascii 128))
  (tag-list (list 10 (string-ascii 32)))
)
  (let
    (
      (doc-id (+ (var-get document-count) u1))
    )
    ;; Input validation
    (asserts! (> (len title) u0) error-invalid-name)
    (asserts! (< (len title) u65) error-invalid-name)
    (asserts! (> file-size u0) error-invalid-size)
    (asserts! (< file-size u1000000000) error-invalid-size)
    (asserts! (> (len description) u0) error-invalid-name)
    (asserts! (< (len description) u129) error-invalid-name)
    (asserts! (validate-tags tag-list) error-invalid-tags)

    ;; Create document record
    (map-insert title-documents
      { doc-id: doc-id }
      {
        title-name: title,
        title-owner: tx-sender,
        document-size: file-size,
        registration-block: block-height,
        property-description: description,
        tags: tag-list
      }
    )

    ;; Set access permission for creator
    (map-insert viewer-permissions
      { doc-id: doc-id, viewer: tx-sender }
      { access-allowed: true }
    )

    ;; Increment document counter
    (var-set document-count doc-id)
    (ok doc-id)
  )
)

;; Update an existing document's metadata
(define-public (update-document
  (doc-id uint)
  (new-title (string-ascii 64))
  (new-size uint)
  (new-description (string-ascii 128))
  (new-tags (list 10 (string-ascii 32)))
)
  (let
    (
      (doc-info (unwrap! (map-get? title-documents { doc-id: doc-id })
        error-document-not-found))
    )
    ;; Validate ownership and input data
    (asserts! (document-exists? doc-id) error-document-not-found)
    (asserts! (is-eq (get title-owner doc-info) tx-sender) error-not-owner)
    (asserts! (> (len new-title) u0) error-invalid-name)
    (asserts! (< (len new-title) u65) error-invalid-name)
    (asserts! (> new-size u0) error-invalid-size)
    (asserts! (< new-size u1000000000) error-invalid-size)
    (asserts! (> (len new-description) u0) error-invalid-name)
    (asserts! (< (len new-description) u129) error-invalid-name)
    (asserts! (validate-tags new-tags) error-invalid-tags)

    ;; Update document with revised information
    (map-set title-documents
      { doc-id: doc-id }
      (merge doc-info {
        title-name: new-title,
        document-size: new-size,
        property-description: new-description,
        tags: new-tags
      })
    )
    (ok true)
  )
)


