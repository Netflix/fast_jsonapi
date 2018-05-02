require 'spec_helper'
require 'active_record'
require 'sqlite3'

describe 'active record' do

  # Setup DB
  before(:all) do
    @db_file = "test.db"

    # Open a database
    db = SQLite3::Database.new @db_file

    # Create tables
    db.execute_batch <<-SQL
      create table suppliers (
        name varchar(30),
        id int primary key
      );

      create table accounts (
        name varchar(30),
        id int primary key,
        supplier_id int,
        FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
      );

      create table cities (
        name varchar(30),
        id int primary key
      );

      create table zip_codes (
        code varchar(5),
        id int primary key,
        primary_city_id int,
        FOREIGN KEY (primary_city_id) REFERENCES cities(id)
      );

      create table locations (
        zip_code_id int,
        city_id int,
        id int primary key,
        is_primary int,
        FOREIGN KEY (city_id) REFERENCES cities(id),
        FOREIGN KEY (zip_code_id) REFERENCES zip_codes(id)
      );

      create table object_with_cities (
        zip_code_id int,
        id int primary key,
        FOREIGN KEY (zip_code_id) REFERENCES zip_codes(id)
      );
    SQL

    # Insert records
    @account_id = 2
    @supplier_id = 1
    @supplier_id_without_account = 3
    @city_id = 1
    @zip_code_id = 1
    db.execute_batch <<-SQL
      insert into suppliers values ('Supplier1', #{@supplier_id}),
                                   ('SupplierWithoutAccount', #{@supplier_id_without_account});
      insert into accounts values ('Dollar Account', #{@account_id}, #{@supplier_id});

      insert into cities values ('Beverly Hills', #{@city_id});
      insert into zip_codes values ('90210', #{@zip_code_id}, #{@city_id});
      insert into locations values (#{@zip_code_id}, #{@city_id}, 1, 1);
      insert into object_with_cities values (#{@zip_code_id}, 1);
    SQL
  end

  # Setup Active Record
  before(:all) do
    class Supplier < ActiveRecord::Base
      has_one :account
    end

    class Account < ActiveRecord::Base
      belongs_to :supplier
    end

    class Location < ActiveRecord::Base
      belongs_to :zip_code
      belongs_to :city
      scope :primary, -> { where(is_primary: 1) }
    end

    class ZipCode < ActiveRecord::Base
      # has_one :primary_loc, -> { where(is_primary: 1) }, class_name: 'Location'
      has_many :locations
      # has_many :cities, through: :locations
    end

    class City < ActiveRecord::Base
      has_many :locations
      has_many :zip_codes, through: :locations
    end

    class ObjectWithCity < ActiveRecord::Base
      belongs_to :zip_code

      has_one :primary_loc, class_name: 'Location', through: :zip_code
      has_one :city, class_name: 'City', through: :primary_loc
    end

    ActiveRecord::Base.establish_connection(
      :adapter => 'sqlite3',
      :database  => @db_file
    )
  end

  context 'with a belongs with a different foreign key' do
    it 'can serialize the results' do
      obj = ObjectWithCity.group('cities.id').select('cities.id city_id').joins(zip_code: { locations: :city }).first

      # Commenting out the code in lib/extensions/has_one.rb will make this pass
      expect(obj.city_id).to be_present
    end
  end

  context 'has one patch' do

    it 'has account_id method for a supplier' do
      expect(Supplier.first.respond_to?(:account_id)).to be true
      expect(Supplier.first.account_id).to eq @account_id
    end

    it 'has account_id method return nil if account not present' do
      expect(Supplier.find(@supplier_id_without_account).account_id).to eq nil
    end

  end

  # Clean up DB
  after(:all) do
    File.delete(@db_file) if File.exist?(@db_file)
  end
end
