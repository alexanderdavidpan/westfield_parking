require "chronic"
require "pony"
require "selenium-webdriver"
require "yaml"

user_data = YAML::load(File.open('config/user_data.yml'))

PREFERRED_PARKING_SPOTS = user_data['preferred_parking_spots'].map(&:to_s)

begin
  days = user_data['days']
  days.each do |day|
    day   = Chronic.parse(day)
    year  = day.year
    month = day.month
    day   = day.day

    # Instantiate driver and navigate to Westfield Parking Reservation page
    driver = Selenium::WebDriver.for :firefox
    driver.navigate.to "https://reservedparking.westfield.com/WestfieldBooking/"

    # Select entry month/year
    entry_month_year_dropdown = driver.find_element(:id, 'entry-month-year')
    option = Selenium::WebDriver::Support::Select.new(entry_month_year_dropdown)
    option.select_by(:value, "#{sprintf('%02d', month)}#{year}")

    # Select entry day
    entry_day_dropdown = driver.find_element(:id, 'entry-day')
    option = Selenium::WebDriver::Support::Select.new(entry_day_dropdown)
    option.select_by(:value, sprintf('%02d', day))

    # Select entry time (must be at least 30 minutes ahead of current time)
    entry_time_dropdown = driver.find_element(:id, 'entry-time')
    option = Selenium::WebDriver::Support::Select.new(entry_time_dropdown)
    option.select_by(:value, user_data['entry_time'].to_s)

    # Select hours of parking required
    hours_of_parking_dropdown = driver.find_element(:id, 'hours-required')
    option = Selenium::WebDriver::Support::Select.new(hours_of_parking_dropdown)
    option.select_by(:value, user_data['hours_of_parking'].to_s)

    # Click on 'Promo Code?' and enter promo code
    wait = Selenium::WebDriver::Wait.new(:timeout =>10) # seconds
    wait.until {
      driver.find_element(:link_text,'Promo code?').click
    }
    promo_code_input = driver.find_element(:id, 'promo_code')
    promo_code_input.send_keys(user_data['promo_code'])

    # Click 'Get Quote' and move quote page
    driver.find_element(class: 'btn-chaunt').click

    sleep 2

    # Select preferred parking spot
    select_your_space = driver.find_element(:link_text, 'Select your space').click

    PREFERRED_PARKING_SPOTS.each do |spot|
      parking_spot = driver.find_element(:xpath, "//*[@id='bays-map']/div[#{spot}]").click
      selected_spot = driver.find_element(:css, ".bay-selected").text
      break if spot == selected_spot
    end

    # Confirm and save spot changes
    driver.find_element(:id, 'bay-close-save-button').click

    sleep 2

    # Check that parking is FREE, then click next
    h1_elements = driver.find_elements(:tag_name, 'h1')
    reservation_price = h1_elements.last.text

    if reservation_price == '$0.00'
      driver.find_element(class: 'book-btn').click
    else
      Pony.mail(
        :to => user_data['email'],
        :from => user_data['email'],
        :body => "The reservation price was not free. It was #{reservation_price}"
      )
    end

    # Fill in details page
    # Title
    title_dropdown = driver.find_element(:id, 'title2')
    option = Selenium::WebDriver::Support::Select.new(title_dropdown)
    option.select_by(:value, user_data['title'])

    # First Name
    first_name_input = driver.find_element(:id, 'firstname')
    first_name_input.send_keys(user_data['first_name'])

    # Last Name
    last_name_input = driver.find_element(:id, 'lastname')
    last_name_input.send_keys(user_data['last_name'])

    # Zip Code
    zip_code_input = driver.find_element(:id, 'postcode')
    zip_code_input.send_keys(user_data['zip_code'])

    # Mobile Number
    mobile_number_input = driver.find_element(:id, 'phoneno')
    mobile_number_input.send_keys(user_data['mobile_number'])

    # Email
    email_input = driver.find_element(:id, 'email')
    email_input.send_keys(user_data['email'])

    # Confirm Email
    confirm_email_input = driver.find_element(:id, 'email_confirm')
    confirm_email_input.send_keys(user_data['email'])

    # Check display name checkbox to hide display name (specified in config)
    if user_data['hide_name']
      hide_name_checkbox = driver.find_element(:id, 'bay_hidename')
      hide_name_checkbox.click
    end

    # Check terms & conditions checkbox
    terms_and_conditions_checkbox = driver.find_element(:id, 'TCCheckbox')
    terms_and_conditions_checkbox.click

    # Uncheck emails/news/offers/deals
    emails_checkbox = driver.find_element(:id, 'custshareinfo')
    emails_checkbox.click

    # Uncheck remember personal details
    remember_details_checkbox = driver.find_element(:id, 'save_details')
    remember_details_checkbox.click

    # Click "Reserve Now" button
    reserve_now_button = driver.find_element(id: 'confirm-and-pay')
    reserve_now_button.click

    sleep 20

    driver.quit
  end
rescue => e
  Pony.mail(
    :to => user_data['email'],
    :from => user_data['email'],
    :body => "An error occured while trying to reserve a parking space. Please be sure to reserve one. The error: #{e.message}"
  )
end
