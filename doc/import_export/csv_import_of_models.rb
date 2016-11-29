


import_file = '/tmp/theater.csv'

def create_model(options, category1, category2)

  m = Model.find_by_product(name)
  if m.nil?
    c1 = Category.find_or_create_by_name(category1) unless category1.blank?
    c2 = Category.find_or_create_by_name(category2) unless category2.blank?

    m = Model.create(product: options[:product],
                     manufacturer: options[:manufacturer])
    m.categories << c1 unless c1.blank? or m.categories.include?(c1)
    m.categories << c2 unless c2.blank? or m.categories.include?(c2)
    m.save
  end


  return m
end

require 'csv'

items_to_import = CSV.open(import_file, col_sep: "\t", headers: true)

items_to_import.each do |row|
  create_model({product: row['Produkt'], manufacturer: row['Hersteller']}, 
               row['Kategorie1'], row['Kategorie2'])
end
