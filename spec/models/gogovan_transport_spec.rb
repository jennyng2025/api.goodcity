require 'rails_helper'

RSpec.describe GogovanTransport, type: :model do

  it { is_expected.to have_db_column(:name_en).of_type(:string) }
  it { is_expected.to have_db_column(:name_zh_tw).of_type(:string) }
  it { is_expected.to have_db_column(:disabled).of_type(:boolean) }
  it { is_expected.to validate_presence_of(:name_en) }

  describe 'instance methods' do
    it '#vehical_tag' do
      expect(
        (build :gogovan_transport, name_en: 'Van').vehicle_tag
      ).to eq('van')
      expect(
        (build :gogovan_transport, name_en: '5.5 Tonne Truck').vehicle_tag
      ).to eq('mudou')
    end
  end
end
