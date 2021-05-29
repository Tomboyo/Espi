{
  ingest_data: [
    generate(MyDataGenerator, :generate_data, []),
    transform(Ingest, :ingest_data, []),
    transform(Validation, :validate_data, []),
    splitter(fn message -> if match?({:ok, _}, message.data),
      do: "validated",
      else: "invalid"
    end),
  ],

  
  handle_invalid_data: [
    from_destination
  ]
}
