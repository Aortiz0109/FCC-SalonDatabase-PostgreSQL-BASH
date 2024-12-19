#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ MY SALON ~~~~~\n"
echo -e "\nWelcome to My Salon, how can I help you today?\n"

MAIN_MENU() {
  # A display argument.
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi
  # Show available services.
  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id;")
  # If there are no services.
  if [[ -z $SERVICES ]]
  then
    echo "Sorry, I could not find that service. What would you like today? e.g. 1"
  # If there is then, display them formatted.
  else 
    echo -e "$SERVICES" | while read SERVICE_ID BAR NAME
    do
      echo "$SERVICE_ID) $NAME."
    done
    # Get customer choice.
    read SERVICE_ID_SELECTED
    # If entry is not a number.
    if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
    then
      # Send to main menu
      MAIN_MENU "Sorry, that is not a valid number. Please enter the number for the service you want to book."
    else
      VALID_SERVICE=$($PSQL "SELECT service_id FROM services WHERE service_id = $SERVICE_ID_SELECTED")
      # If it is a number but, not referenced in database.
      if [[ -z $VALID_SERVICE ]]
      then
        # Send to main menu
        MAIN_MENU "I couldn't find that service listed. Please choose again."
      else
        # Get customer phone number.
        echo -e "\n What's your phone number? e.g. 555-5555"
        read CUSTOMER_PHONE
        # Check if its a new customer.
        CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")
        # If it is a new customer.
        if [[ -z $CUSTOMER_NAME ]]
        then
          # Get name, phone and add to table.
          echo -e "\nI don't have a record for that number, what's your name?"
          read CUSTOMER_NAME
          CUSTOMER_INFO_INCLUSION=$($PSQL "INSERT INTO customers(phone, name) VALUES ('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")
          SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
          # Get the time the customer wants to appoint.
          echo "What time would you like your $(TRIM "$SERVICE_NAME"), $(TRIM "$CUSTOMER_NAME")?"
          read SERVICE_TIME
          # Update the appointment table, let customer know it's confirmed.
          CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
          APPOINTMENT_INCLUSION=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
          echo -e "\nI have put you down for a $(TRIM "$SERVICE_NAME") at $SERVICE_TIME, $(TRIM "$CUSTOMER_NAME")."
        # If it's an existing customer.
        else
        # Get the service name and ask for the time.
        SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
        echo "What time would you like your $(TRIM "$SERVICE_NAME"), $(TRIM "$CUSTOMER_NAME")?"
        read SERVICE_TIME
        # Update the appointments table, and let customer know it's confirmed.
        CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
        APPOINTMENT_INCLUSION=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
        echo -e "\nI have put you down for a $(TRIM "$SERVICE_NAME") at $SERVICE_TIME, $(TRIM "$CUSTOMER_NAME")."
        fi
      fi
    fi
  fi  
}

TRIM() {
  echo "$1" | sed -r 's/^ *| *$//g'
}

MAIN_MENU