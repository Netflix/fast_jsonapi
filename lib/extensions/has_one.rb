# frozen_string_literal: true

begin
  require 'active_record'

  ::ActiveRecord::Associations::Builder::HasOne.class_eval do
    # Based on
    # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/associations/builder/collection_association.rb#L50
    # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/associations/builder/singular_association.rb#L11
    def self.define_accessors(mixin, reflection)
      super
      name = reflection.name
      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name.to_s}_id
          association(:#{name}).reader.try(:id)
        end
      CODE
    end
  end
rescue LoadError
  # active_record can't be loaded so we shouldn't try to monkey-patch it.
end
