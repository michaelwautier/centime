class BankConnection < ApplicationRecord
  CONSENT_WARNING_WINDOW = 7.days

  belongs_to :user
  has_many :bank_accounts, dependent: :destroy

  enum :status, {
    pending: "pending",   # requisition created, user not back from the bank yet
    linked: "linked",
    expiring: "expiring", # consent ends within the warning window
    expired: "expired",
    revoked: "revoked",
    paused: "paused",     # over the free-plan limit after a downgrade
    error: "error"
  }, prefix: true

  validates :institution_id, :institution_name, :reference, presence: true
  validates :reference, uniqueness: true
  validates :requisition_id, uniqueness: true, allow_nil: true

  scope :syncable, -> { where(status: [ :linked, :expiring ]) }

  def syncable? = status_linked? || status_expiring?

  def manual_sync_available? = syncable? && last_manual_sync_on != Date.current

  def consent_expiring_soon?
    consent_expires_at.present? && consent_expires_at < CONSENT_WARNING_WINDOW.from_now
  end
end
