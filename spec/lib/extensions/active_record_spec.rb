require "spec_helper"
require "active_record"
require "sqlite3"
require "pry"

describe "active record" do
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
    @supplier_id_without_account = 3
    db.execute_batch <<-SQL
      insert into suppliers values ("Supplier1", #{@supplier_id}),
                                   ("SupplierWithoutAccount", #{@supplier_id_without_account});
      insert into accounts values ("Dollar Account", #{@account_id}, #{@supplier_id});
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
      adapter: "sqlite3",
      database: @db_file
    )
  end

  context "has one patch" do
    it "has account_id method for a supplier" do
      expect(Supplier.first.respond_to?(:account_id)).to be true
      expect(Supplier.first.account_id).to eq @account_id
    end

    it "has account_id method return nil if account not present" do
      expect(Supplier.find(@supplier_id_without_account).account_id).to eq nil
    end
  end

  # Clean up DB
  after(:all) do
    File.delete(@db_file) if File.exist?(@db_file)
  end
end

describe "active record has_one through" do
  # Setup DB
  before(:all) do
    @db_file = "test_two.db"

    # Open a database
    db = SQLite3::Database.new @db_file

    # Create tables
    db.execute_batch <<-SQL
      create table forests (
        id int primary key,
        name varchar(30)
      );

      create table trees (
        id int primary key,
        forest_id int,
        name varchar(30),

        FOREIGN KEY (forest_id) REFERENCES forests(id)
      );

      create table fruits (
        id int primary key,
        tree_id int,
        name varchar(30),

        FOREIGN KEY (tree_id) REFERENCES trees(id)
      );
    SQL

    # Insert records
    db.execute_batch <<-SQL
      insert into forests values (1, 'sherwood');
      insert into trees values (2, 1,'pine');
      insert into fruits values (3, 2, 'pine nut');

      insert into fruits(id,name) values (4,'apple');
    SQL
  end

  # Setup Active Record
  before(:all) do
    class Forest < ActiveRecord::Base
      has_many :trees
    end

    class Tree < ActiveRecord::Base
      belongs_to :forest
    end

    class Fruit < ActiveRecord::Base
      belongs_to :tree
      has_one :forest, through: :tree
    end

    ActiveRecord::Base.establish_connection(
      adapter: "sqlite3",
      database: @db_file
    )
  end

  context "revenue" do
    it "has an forest_id" do
      expect(Fruit.find(3).respond_to?(:forest_id)).to be true
      expect(Fruit.find(3).forest_id).to eq 1
      expect(Fruit.find(3).forest.name).to eq "sherwood"
    end

    it "has nil if tree id not available" do
      expect(Fruit.find(4).respond_to?(:tree_id)).to be true
      expect(Fruit.find(4).forest_id).to eq nil
    end
  end

  # Clean up DB
  after(:all) do
    File.delete(@db_file) if File.exist?(@db_file)
  end
end
