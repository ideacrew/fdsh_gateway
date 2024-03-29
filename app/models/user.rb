# frozen_string_literal: true

# The User class represents a user in the system.
# It includes Mongoid::Document to map the class to the MongoDB document.
# It uses the Devise gem for user authentication, including modules for database authentication,
# password recovery, remember me functionality, tracking sign-in count and IP, session limiting, and account expiry.
# The class defines fields for each of these functionalities.
#
# @!attribute email
#   @return [String] the user's email address
# @!attribute encrypted_password
#   @return [String] the user's encrypted password
# @!attribute reset_password_token
#   @return [String] the token for resetting the user's password
# @!attribute reset_password_sent_at
#   @return [Time] the time the reset password email was sent
# @!attribute remember_created_at
#   @return [Time] the time the remember me cookie was created
# @!attribute sign_in_count
#   @return [Integer] the number of times the user has signed in
# @!attribute current_sign_in_at
#   @return [Time] the time of the current sign in
# @!attribute last_sign_in_at
#   @return [Time] the time of the last sign in
# @!attribute current_sign_in_ip
#   @return [String] the IP of the current sign in
# @!attribute last_sign_in_ip
#   @return [String] the IP of the last sign in
# @!attribute last_activity_at
#   @return [Time] the time of the last activity
# @!attribute expired_at
#   @return [Time] the time the account expired
# @!attribute unique_session_id
#   @return [String] the unique session ID
class User
  include Mongoid::Document
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable,
         :trackable, :session_limitable, :expirable, :registerable

  ## Database authenticatable
  field :email,              type: String, default: ""
  field :encrypted_password, type: String, default: ""

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  # expirable
  field :last_activity_at, type: Time
  field :expired_at, type: Time

  field :unique_session_id, type: String

  index({ unique_session_id: 1 })
  index({ last_activity_at: 1 })
  index({ expired_at: 1 })
  ## Trackable
  # field :sign_in_count,      type: Integer, default: 0
  # field :current_sign_in_at, type: Time
  # field :last_sign_in_at,    type: Time
  # field :current_sign_in_ip, type: String
  # field :last_sign_in_ip,    type: String

  ## Confirmable
  # field :confirmation_token,   type: String
  # field :confirmed_at,         type: Time
  # field :confirmation_sent_at, type: Time
  # field :unconfirmed_email,    type: String # Only if using reconfirmable

  ## Lockable
  # field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  # field :locked_at,       type: Time
  include Mongoid::Timestamps
end
