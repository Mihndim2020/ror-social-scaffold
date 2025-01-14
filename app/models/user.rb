class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, presence: true, length: { maximum: 20 }
  validates :email, presence: true, length: { minimum: 6 }, uniqueness: true

  has_many :posts
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :friendships

  has_many :pending_friendships, class_name: 'Friendship', foreign_key: 'user_id'
  has_many :pending_friends, through: :pending_friendships, source: :friend

  has_many :inverse_friendships, class_name: 'Friendship', foreign_key: 'friend_id'
  has_many :friend_requests, through: :inverse_friendships, source: :user

  has_many :confirmed_friendships, -> { where status: true }, class_name: 'Friendship'
  has_many :friends, through: :confirmed_friendships

  has_many :inverted_friendships, -> { where status: false }, class_name: 'Friendship', foreign_key: 'friend_id'

  has_many :requested_friends, -> { where status: false }, class_name: 'Friendship', foreign_key: 'friend_id'

  def friends
    friends_array = friendships.map { |friendship| friendship.friend if friendship.status }
    friends_array.compact
  end

  def confirm_friend(user)
    friendship = inverse_friendships.find_by(user_id: user.id)
    friendship.status = true
    friendship.save
  end

  def reject_friend(user)
    friendship = inverse_friendships.find_by(user_id: user.id)
    friendship.destroy
  end

  def send_request(user)
    friendship = inverse_friendships.find_by(user_id: user.id)
    friendship.send = true
    friendship.destroy
  end

  def cancel_request(user)
    friendship = friendships.find_by(friend_id: user.id)
    friendship.destroy
  end

  def friend?(user)
    friends.include?(user)
  end

  def friend_requests
    inverse_friendships.map { |friendship| friendship.user unless friendship.status }.compact
  end

  def user_friend
    friend_ids = friends.map(&:id)
    friend_ids << id
    Post.all.where(user_id: friend_ids)
  end

  def friends_and_own_posts
    Post.where(user: (friends.to_a << self))
    # This will produce SQL query with IN. Something like: select * from posts where user_id IN (1,45,874,43);
  end
end
