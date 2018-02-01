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
    SQL

    # Insert records
    @account_id = 2
    @supplier_id = 1
    db.execute_batch <<-SQL
      insert into suppliers values ('Supplier1', #{@supplier_id});
      insert into accounts values ('Dollar Account', #{@account_id}, #{@supplier_id});
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

    ActiveRecord::Base.establish_connection(
      :adapter => 'sqlite3',
      :database  => @db_file
    )
  end

  context 'has one patch' do

    it 'has account_id method for a supplier' do
      expect(Supplier.first.respond_to?(:account_id)).to be true
      expect(Supplier.first.account_id).to eq @account_id
    end

  end

  # Clean up DB
  after(:all) do
    File.delete(@db_file) if File.exist?(@db_file)
  end
end
