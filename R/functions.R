kable_table <- function(dog) {
  dog %>% 
    dplyr::mutate(vaccine_date_expires = kableExtra::cell_spec(vaccine_date_expires, "html", color = ifelse(days_to_expiration <= 30, "red", "green")),
           days_to_expiration = formattable::color_tile("white", "orange")(days_to_expiration)) %>% 
    dplyr::select(pet_name, vaccine_name, vaccine_date_given, vaccine_date_expires, vet_name, vet_phone, vet_website, vet_email, days_to_expiration) %>% 
    kableExtra::kable(format = "html", escape = F) %>% 
    kableExtra::kable_styling(bootstrap_options = c("striped", "hover"))
}

get_data <- function(dog_name, table, connection) {
  RMySQL::dbReadTable(connection, table) %>% 
    dplyr::filter(vaccine_current_flag == "Y", pet_name == dog_name) 
}