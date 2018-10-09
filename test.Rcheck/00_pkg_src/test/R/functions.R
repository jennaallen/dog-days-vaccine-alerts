kable_table <- function(dog) {
  dog %>% 
    dplyr::mutate(vaccine_date_expires = kableExtra::cell_spec(.data$vaccine_date_expires, "html", color = ifelse(.data$days_to_expiration <= 30, "red", "green")),
           days_to_expiration = formattable::color_tile("white", "orange")(.data$days_to_expiration)) %>% 
    dplyr::select(.data$pet_name, .data$vaccine_name, .data$vaccine_date_given, .data$vaccine_date_expires, .data$vet_name, .data$vet_phone, .data$vet_website, .data$vet_email, .data$days_to_expiration) %>% 
    kableExtra::kable(format = "html", escape = F) %>% 
    kableExtra::kable_styling(bootstrap_options = c("striped", "hover"))
}

get_data <- function(dog_name, table, connection) {
  RMySQL::dbReadTable(connection, table) %>% 
    dplyr::filter(.data$vaccine_current_flag == "Y", .data$pet_name == dog_name) 
}