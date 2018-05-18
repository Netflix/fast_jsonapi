require 'skylight'

SKYLIGHT_NORMALIZER_BASE_CLASS = begin
  ::Skylight::Core::Normalizers::Normalizer
rescue NameError
  ::Skylight::Normalizers::Normalizer
end
