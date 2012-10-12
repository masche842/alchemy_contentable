Alchemy::Content.class_eval do

  attr_accessible(
    :do_not_index,
    :element_id,
    :essence_id,
    :essence_type,
    :name,
    :position
  )

end