# westfield_parking

A selenium script to reserve parking at Westfield Century City (because I'm lazy).

## Dependencies

You will need to have Ruby installed. You will also need to install the chronic, pony, selenium-webdriver, and yaml gems to run the script.

```
gem install chronic
gem install pony
gem install selenium-webdriver
gem install yaml
```

Browser dependencies:

* **Chrome**: Coming soon...

* **Firefox**: Download [Mozilla geckodriver](https://github.com/mozilla/geckodriver/releases) and place it somewhere on your PATH. I just moved the geckodriver bin file to `/usr/local/bin`.

* **Safari**: Coming soon...

## Usage

1. Clone the repository and navigate to project root directory.
```
git clone https://github.com/alexanderdavidpan/westfield_parking.git
cd westfield_parking
```

2. Fill out the `config/user_data.yml` file with your information.

3. Run the script:

```
ruby reserve.rb
```
