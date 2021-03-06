class User < ApplicationRecord
  has_secure_password
  has_many :vendor_items
  has_many :items, through: :vendor_items

  acts_as_mappable  :default_units => :miles,
                    :default_formula => :sphere,
                    :distance_field_name => :distance,
                    :lat_column_name => :lat,
                    :lng_column_name => :long

  before_validation :geocode_address, :on => [:create, :update]


  validates :email, uniqueness: true, presence: true

  validates_presence_of :name,
                        :account_type,
                        :address,
                        :city,
                        :state,
                        :zip,
                        :phone,
                        :lat,
                        :long,
                        :bio,
                        :password

  enum account_type: [:vendor, :customer]

  def self.all_vendors
    User.where('account_type = ?', 0)
  end

  def self.vendor_search_with_item(item_id, range, location)
    Item.find(item_id)
      .users
      .within(range, :origin => location)
      .where('account_type = ?', 0)
  end

  def self.vendor_search_without_item(range, location)
    User.within(range, :origin => location)
      .where('account_type = ?', 0)
  end

private

  def geocode_address
    formatted = "#{address}, #{city}, #{state} #{zip}"
    geo = Geokit::Geocoders::MultiGeocoder.geocode (formatted)
    errors.add(:address, "Could not Geocode address") if !geo.success
    self.lat, self.long = geo.lat, geo.lng if geo.success
  end

end