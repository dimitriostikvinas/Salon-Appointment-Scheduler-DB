#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"
echo -e "\n~~~~~ My Salon ~~~~~\n"

MAIN_MENU() {
  if [[ $1 ]]
  then
    echo -e "\n$1\n"
  else
    echo -e "Welcome to My Salon, how can I help you?\n"
  fi
  DISPLAY_MENU
  read SERVICE_ID_SELECTED
  # check if it's not a number
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    MAIN_MENU "Please provide a valid service number"
  else
    SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")
    # check if there exists a service with the given id
    if [[ -z $SERVICE_NAME ]]
    then
      MAIN_MENU "I could not find that service. What would you like today?"
    else
      HANDLE_SERVICE "$SERVICE_NAME" "$SERVICE_ID_SELECTED"
    fi
  fi
}

DISPLAY_MENU() {
  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")
  echo "$SERVICES" | while read SERVICE_ID BAR NAME
  do
    echo "$SERVICE_ID) $NAME"
  done
}

HANDLE_SERVICE() {
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  # Sanitize the phone number input
  CUSTOMER_PHONE=$(echo "$CUSTOMER_PHONE" | sed -r 's/[^0-9]//g')

  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")
  if [[ -z $CUSTOMER_NAME ]]
  then
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME
    # Sanitize the customer name input
    CUSTOMER_NAME=$(echo "$CUSTOMER_NAME" | sed -r "s/'/''/g")
    INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(phone, name) VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")
    if [[ $? -ne 0 ]]
    then
      echo -e "\nError: Could not insert customer. Please try again."
      exit 1
    fi
  else
    CUSTOMER_NAME=$(echo "$CUSTOMER_NAME" | sed -r 's/^ *| *$//g')
  fi

  echo -e "\nWhat time would you like your $1, $CUSTOMER_NAME?"
  read SERVICE_TIME

  # Sanitize the service time input
  SERVICE_TIME=$(echo "$SERVICE_TIME" | sed -r 's/[^0-9:]//g')

  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
  INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(time, customer_id, service_id) VALUES('$SERVICE_TIME', $CUSTOMER_ID, $2)")
  if [[ $? -ne 0 ]]
  then
    echo -e "\nError: Could not book appointment. Please try again."
    exit 1
  fi

  echo -e "\nI have put you down for a $1 at $SERVICE_TIME, $CUSTOMER_NAME."
}

MAIN_MENU
