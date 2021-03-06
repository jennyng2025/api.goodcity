class Gogovan

  attr_accessor :user, :name, :mobile, :time, :need_english,
    :need_cart, :need_carry, :district_id, :vehicle, :ggv_uuid, :offer

  def initialize(user = nil, options = {})
    @user         = user
    @name         = options['name']
    @mobile       = options['mobile']
    @time         = options['pickupTime'] || get_pickup_date
    @need_english = options['needEnglish']
    @need_cart    = options['needCart']
    @need_carry   = options['needCarry']
    @district_id  = options['districtId']
    @vehicle      = options['vehicle']
    @ggv_uuid     = options['ggv_uuid']
    @offer        = Offer.find_by(id: options['offerId'])
  end

  def confirm_order
    order.book
  end

  def get_order_price
    order.price
  end

  class << self

    def order_status(booking_id)
      GoGoVanApi::Order.new(booking_id).status
    end

    def cancel_order(booking_id)
      GoGoVanApi::Order.new(booking_id).cancel
    end

  end

  private

  def order
    GoGoVanApi::Order.new(nil, order_attributes)
  end

  def order_attributes
    {
      order: {
        name:           @name || @user.full_name,
        phone_number:   @mobile || @user.mobile,
        pickup_time:    parse_time.utc,
        vehicle:        @vehicle,
        locations:      locations,
        extra_requirements: {
          need_english: @need_english,
          need_cart:    @need_cart,
          need_carry:   @need_carry,
          remark:       ggv_driver_notes
        }
      }
    }
  end

  def locations
    pickup_district = District.find(@district_id)
    pickup_location = pickup_district.lat_lng_name
    [pickup_location, District.crossroads_address].to_json
  end

  def get_pickup_date
    next_available_date = DateSet.new().available_dates.first
    next_available_date.beginning_of_day + 12.hours
  end

  def ggv_driver_notes
    if offer && ggv_uuid
      link = "#{Rails.application.secrets.base_urls["app"]}/ggv_orders/#{ggv_uuid}"
      I18n.t('gogovan.driver_note', link: "#{link}?ln=en", ch_link: "#{link}?ln=zh-tw")
    end
  end

  def parse_time
    @time.is_a?(DateTime) ? @time : DateTime.parse(@time.to_s)
  end

end
