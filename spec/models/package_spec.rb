require 'rails_helper'

RSpec.describe Package, type: :model do

  let(:package) { create :package }

  describe "Associations" do
    it { is_expected.to belong_to :item }
    it { is_expected.to belong_to :package_type }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:length).of_type(:integer)}
    it{ is_expected.to have_db_column(:width).of_type(:integer)}
    it{ is_expected.to have_db_column(:height).of_type(:integer)}
    it{ is_expected.to have_db_column(:quantity).of_type(:integer)}
    it{ is_expected.to have_db_column(:notes).of_type(:text)}
    it{ is_expected.to have_db_column(:state).of_type(:string)}
    it{ is_expected.to have_db_column(:received_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:rejected_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:designation_name).of_type(:string)}
    it{ is_expected.to have_db_column(:grade).of_type(:string)}
    it{ is_expected.to have_db_column(:donor_condition_id).of_type(:integer)}
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:package_type_id) }

    let(:attributes) { [:width, :length, :height] }
    it { attributes.each { |attribute| is_expected.to allow_value(nil).for(attribute) } }

    it do
      [:quantity, :length].each do |attribute|
        is_expected.to_not allow_value(0).for(attribute)
        is_expected.to_not allow_value(100000000).for(attribute)
        is_expected.to allow_value(rand(1..99999999)).for(attribute)
      end
    end

    it do
      [:width, :height].each do |attribute|
        is_expected.to_not allow_value(0).for(attribute)
        is_expected.to_not allow_value(100000).for(attribute)
        is_expected.to allow_value(rand(1..99999)).for(attribute)
      end
    end
  end

  describe "state" do
    describe "#mark_received" do
      it "should set received_at value" do
        expect(Stockit::Item).to receive(:create).with(package)
        expect{
          package.mark_received
        }.to change(package, :received_at)
        expect(package.state).to eq("received")
      end
    end

    describe "#mark_missing" do
      let(:package) { create :package, :received }
      it "should set received_at value" do
        expect(Stockit::Item).to receive(:delete).with(package.inventory_number)
        expect{
          package.mark_missing
        }.to change(package, :received_at).to(nil)
        expect(package.state).to eq("missing")
      end
    end
  end

  describe "add_to_stockit" do
    it "should add API errors to package.errors" do
      api_response = {"errors" => {"code" => "can't be blank"}}
      expect(Stockit::Item).to receive(:create).with(package).and_return(api_response)
      package.add_to_stockit
      expect(package.errors).to include(:code)
    end
  end

  describe "remove_from_stockit" do
    it "should add API errors to package.errors" do
      package.inventory_number = "F12345"
      api_response = {"errors" => {"base" => "already designated"}}
      expect(Stockit::Item).to receive(:delete).with(package.inventory_number).and_return(api_response)
      package.remove_from_stockit
      expect(package.errors).to include(:base)
      expect(package.inventory_number).to_not be_nil
    end

    it "should add set inventory_number to nil" do
      package.inventory_number = "F12345"
      expect(Stockit::Item).to receive(:delete).with(package.inventory_number).and_return({})
      package.remove_from_stockit
      expect(package.errors.full_messages).to eq([])
      expect(package.inventory_number).to be_nil
    end
  end

  describe "#offer" do
    it "should return related offer" do
      package = create :package, :with_item
      expect(package.offer).to eq(package.item.offer)
    end
  end

  context "has_paper_trail" do
    it { is_expected.to be_versioned }
  end

  describe "before_save" do
    it "should set grade and donor_condition value" do
      item = create :item
      package = build :package, item: item
      expect {
        package.save
      }.to change(package, :donor_condition).from(nil).to(item.donor_condition)
      expect(package.grade).to eq("B")
    end
  end
end
