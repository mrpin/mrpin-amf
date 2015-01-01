class ExternalizableTest
  include RocketAMF::Pure::IOHelperRead
  include RocketAMF::Pure::IOHelperWrite

  attr_accessor :one, :two

  #
  # Methods
  #

  def encode_amf(serializer)
    serializer.write_object(self, nil, {class_name: 'ExternalizableTest', dynamic: false, externalizable: true, members: []})
  end

  def read_external(deserializer)
    @one = read_double(deserializer.source)
    @two = read_double(deserializer.source)
  end

  def write_external(serializer)
    serializer.stream << pack_double(@one)
    serializer.stream << pack_double(@two)
  end
end