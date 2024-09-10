## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
    collapse = TRUE,
    comment = "#>"
)

## ----eval = FALSE-------------------------------------------------------------
#  # Install the package from the source
#  remotes::install_github("dereckmezquita/interface")

## ----setup--------------------------------------------------------------------
box::use(interface[interface, type.frame, fun, enum])

## -----------------------------------------------------------------------------
# Define an interface
Person <- interface(
    name = character,
    age = numeric,
    email = character
)

# Implement the interface
john <- Person(
    name = "John Doe",
    age = 30,
    email = "john@example.com"
)

print(john)

# interfaces are lists
print(john$name)

# Valid assignment
john$age <- 10

print(john$age)

# Invalid assignment (throws error)
try(john$age <- "thirty")

## -----------------------------------------------------------------------------
# Define an Address interface
Address <- interface(
    street = character,
    city = character,
    postal_code = character
)

# Define a Scholarship interface
Scholarship <- interface(
    amount = numeric,
    status = logical
)

# Extend the Person and Address interfaces
Student <- interface(
    extends = c(Address, Person), # will inherit properties from Address and Person
    student_id = character,
    scores = data.table::data.table,
    scholarship = Scholarship # nested interface
)

# Implement the extended interface
john_student <- Student(
    name = "John Doe",
    age = 30,
    email = "john@example.com",
    street = "123 Main St",
    city = "Small town",
    postal_code = "12345",
    student_id = "123456",
    scores = data.table::data.table(
        subject = c("Math", "Science"),
        score = c(95, 88)
    ),
    scholarship = Scholarship(
        amount = 5000,
        status = TRUE
    )
)

print(john_student)

## -----------------------------------------------------------------------------
is_valid_email <- function(x) {
    grepl("[a-z|0-9]+\\@[a-z|0-9]+\\.[a-z|0-9]+", x)
}

UserProfile <- interface(
    username = character,
    email = is_valid_email,
    age = function(x) is.numeric(x) && x >= 18
)

# Implement with valid data
valid_user <- UserProfile(
    username = "john_doe",
    email = "john@example.com",
    age = 25
)

print(valid_user)

# Invalid implementation (throws error)
try(UserProfile(
    username = "jane_doe",
    email = "not_an_email",
    age = "30"
))

## -----------------------------------------------------------------------------
# Define an enum for days of the week
DaysOfWeek <- enum("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")

# Create an enum object
today <- DaysOfWeek("Wednesday")
print(today)

# Valid assignment
today$value <- "Friday"
print(today)

# Invalid assignment (throws error)
try(today$value <- "NotADay")

## -----------------------------------------------------------------------------
# Define an interface using an enum
Meeting <- interface(
    title = character,
    day = DaysOfWeek,
    start_time = numeric,
    duration = numeric
)

# Create a valid meeting object
standup <- Meeting(
    title = "Daily Standup",
    day = "Monday",
    start_time = 9.5,  # 9:30 AM
    duration = 0.5  # 30 minutes
)

print(standup)

# Invalid day (throws error)
try(Meeting(
    title = "Invalid Meeting",
    day = "InvalidDay",
    start_time = 10,
    duration = 1
))

## -----------------------------------------------------------------------------
# Define an interface with an in-place enum
Task <- interface(
    description = character,
    priority = enum("Low", "Medium", "High"),
    status = enum("Todo", "InProgress", "Done")
)

# Create a task object
my_task <- Task(
    description = "Complete project report",
    priority = "High",
    status = "InProgress"
)

print(my_task)

# Update task status
my_task$status$value <- "Done"
print(my_task)

# Invalid priority (throws error)
try(my_task$priority$value <- "VeryHigh")

## -----------------------------------------------------------------------------
typed_fun <- fun(
    x = numeric,
    y = numeric,
    return = numeric,
    impl = function(x, y) {
        return(x + y)
    }
)

# Valid call
print(typed_fun(1, 2))  # [1] 3

# Invalid call (throws error)
try(typed_fun("a", 2))

## -----------------------------------------------------------------------------
typed_fun2 <- fun(
    x = c(numeric, character),
    y = numeric,
    return = c(numeric, character),
    impl = function(x, y) {
        if (is.numeric(x)) {
            return(x + y)
        } else {
            return(paste(x, y))
        }
    }
)

print(typed_fun2(1, 2))  # [1] 3
print(typed_fun2("a", 2))  # [1] "a 2"

## -----------------------------------------------------------------------------
PersonFrame <- type.frame(
    frame = data.frame, 
    col_types = list(
        id = integer,
        name = character,
        age = numeric,
        is_student = logical
    )
)

# Create a data frame
persons <- PersonFrame(
    id = 1:3,
    name = c("Alice", "Bob", "Charlie"),
    age = c(25, 30, 35),
    is_student = c(TRUE, FALSE, TRUE)
)

print(persons)

# Invalid modification (throws error)
try(persons$id <- letters[1:3])

## -----------------------------------------------------------------------------
PersonFrame <- type.frame(
    frame = data.frame,
    col_types = list(
        id = integer,
        name = character,
        age = numeric,
        is_student = logical,
        gender = enum("M", "F"),
        email = function(x) all(grepl("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", x)) # functions are applied to whole column
    ),
    freeze_n_cols = FALSE,
    row_callback = function(row) {
        if (row$age >= 40) {
            return(sprintf("Age must be less than 40 (got %d)", row$age))
        }
        if (row$name == "Yanice") {
            return("Name cannot be 'Yanice'")
        }
        return(TRUE)
    },
    allow_na = FALSE,
    on_violation = "error"
)

df <- PersonFrame(
    id = 1:3,
    name = c("Alice", "Bob", "Charlie"),
    age = c(25, 35, 35),
    is_student = c(TRUE, FALSE, TRUE),
    gender = c("F", "M", "M"),
    email = c("alice@test.com", "bob_no_valid@test.com", "charlie@example.com")
)

print(df)
summary(df)

# Invalid row addition (throws error)
try(rbind(df, data.frame(
    id = 4,
    name = "David",
    age = 500,
    is_student = TRUE,
    email = "d@test.com"
)))

