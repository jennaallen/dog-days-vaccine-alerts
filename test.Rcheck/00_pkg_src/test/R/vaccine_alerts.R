# steps:
# go to pet database and get vaccine expiration date information
# filter for current vaccines
# generate a report for each animal
# send email/slack alert if vaccine due within 1 month from date
# automate so that report is generated weekly
# triggers: if any expiration date of vaccine table is within 1 month of today and if the report is different

#make(prework = "devtools::load_all()")
# connect to AWS RDS
con <- RMySQL::dbConnect(RMySQL::MySQL(),
                 username = Sys.getenv("RDSpetsuser"),
                 password = Sys.getenv("RDSpetspw"),
                 host = Sys.getenv("RDShost"),
                 dbname = 'PetRecords')

run_flag <- as.numeric(DBI::dbGetQuery(con, "SELECT MIN(days_to_expiration) as min_date 
                                       FROM viewVaccinesPetsVets
                                       WHERE vaccine_current_flag = 'Y'"))


#source(functions.R)

# max_cu_date <- dbGetQuery(con, "SELECT MAX(cu_date) AS max_cu_date
#                                 FROM viewMaxVaccineCreatedUpdatedDates")
# 
# data_plan <- drake_plan(
#   layla = target(get_data("Layla", "viewVaccinesPetsVets", con), trigger(change = max_cu_date)),
#   lloyd = target(get_data("Lloyd", "viewVaccinesPetsVets", con), trigger(change = max_cu_date)),
#   strings_in_dots = "literals"
# )

data_plan <- drake::drake_plan(
  layla = get_data("Layla", "viewVaccinesPetsVets", con),
  lloyd = get_data("Lloyd", "viewVaccinesPetsVets", con),
  strings_in_dots = "literals"
)

output_types <- drake::drake_plan(
  table = kable_table(dataset__)
)

output_plan <- drake::plan_analyses(
  plan = output_types,
  datasets = data_plan
)

# to get slack to work I had to generate a token here https://api.slack.com/custom-integrations/legacy-tokens
slackr::slackrSetup(channel = "#messages", incoming_webhook_url = Sys.getenv("incoming_webhook_url"), api_token = Sys.getenv("api_token"))

report_plan <- drake::drake_plan(
  report = rmarkdown::render(
    knitr_in("alerts.Rmd"),
    output_file = file_out("report.html"),
    quiet = TRUE),
  notification = target(slackr::slackr("A new vaccine report is ready"), trigger = drake::trigger(change = file.info(drake::knitr_in("report.html"))$ctime)),
  strings_in_dots = "literals"
)

whole_plan <- drake::bind_plans(
  data_plan,
  output_plan,
  report_plan
)

# library(drake)
# config <- drake_config(whole_plan)
# vis_drake_graph(config)

# if (days_to_expiration <= 30) {
#   make(whole_plan)
# }

drake::make(whole_plan, cache_log_file = "cache_log.txt")

# disconnect from RDS
RMySQL::dbDisconnect(con)
        