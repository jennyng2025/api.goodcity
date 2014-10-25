class Message < ActiveRecord::Base
  include Paranoid
  include StateMachineScope

  attr_accessor :state

  belongs_to :recipient, class_name: "User", inverse_of: :messages
  belongs_to :sender, class_name: "User", inverse_of: :sent_messages
  belongs_to :offer, inverse_of: :messages
  belongs_to :item, inverse_of: :messages

  has_many :subscriptions, dependent: :destroy
  has_many :offers_subscription, class_name: "Offer", through: :subscriptions

  scope :with_eager_load, ->{ eager_load( [:sender] ) }

  before_save :set_recipient, unless: "is_private"

  def state_for(current_user)
    Subscription.where("user_id=? and message_id=?", current_user.id, id).first.try(:state)
  end

  def self.current_user_messages(current_user, message_id=nil)
    messages_with_state = Message.joins("LEFT OUTER JOIN subscriptions
    ON subscriptions.message_id = messages.id and
    subscriptions.offer_id = messages.offer_id").
    where("subscriptions.user_id=? or subscriptions.user_id is NULL", current_user).
    select("messages.*, COALESCE(subscriptions.state, 'never-subscribed') as state")

    message_id.blank? ? messages_with_state : (messages_with_state.where("messages.id =?", message_id).first)
  end

  def save_with_subscriptions()
    save
    subscribe_users_to_message
    update_ember_store
    send_new_message_notification
    Message.current_user_messages(sender_id, self.id)
  end

  private

  def subscribe_users_to_message
    users_ids = self.offer.subscribed_users(self.is_private).pluck(:id) - [sender_id]
    users_ids.each do |user_id|
      subscriptions.create(state: "unread", message_id: id, offer_id: offer_id, user_id: user_id)
    end
    subscriptions.create(state: self.state, message_id: id, offer_id: offer_id, user_id: sender_id)

    #subscribe donor if not already subscribed
    if !self.is_private && subscriptions.where(user_id: self.offer.created_by_id).empty?
      subscriptions.create(state: "unread", message_id: id, offer_id: offer_id, user_id: self.offer.created_by_id)
    end
  end

  def subscribed_user_channels
    Channel.users(self.offer.subscribed_users(self.is_private))
  end

  def send_new_message_notification
    subscribed_user_channels = subscribed_user_channels()
    text = self.body.truncate(150, separator: ' ')

    #notify subscribed users except sender
    channels = subscribed_user_channels - Channel.user(self.sender)
    PushService.send_notification(text, "message", self, channels) unless channels.empty?

    #notify all supervisors if no supervisor is subscribed in private thread
    if self.is_private && (Channel.users(User.supervisors) & subscribed_user_channels).empty?
      PushService.send_notification(text, "message", self, Channel.supervisor)
    end
  end

  def update_ember_store
    sender_channel = Channel.user(self.sender) #remove sender channel to prevent duplicates
    subscribed_user_channels = subscribed_user_channels() - sender_channel
    unsubscribed_user_channels = Channel.users(User.staff) - subscribed_user_channels - sender_channel

    orig_state = self.state
    self.state = "unread"
    PushService.update_store(self, nil, subscribed_user_channels) unless subscribed_user_channels.empty?
    self.state = "never-subscribed"
    PushService.update_store(self, nil, unsubscribed_user_channels) unless unsubscribed_user_channels.empty?
    self.state = orig_state
  end

  def set_recipient
    self.recipient_id = offer.created_by_id if offer_id
  end
end
