module Plutus
  # The Account class represents accounts in the system. Each account must be subclassed as one of the following types:
  #
  #   TYPE        | NORMAL BALANCE    | DESCRIPTION
  #   --------------------------------------------------------------------------
  #   Asset       | Debit             | Resources owned by the Business Entity
  #   Liability   | Credit            | Debts owed to outsiders
  #   Equity      | Credit            | Owners rights to the Assets
  #   Revenue     | Credit            | Increases in owners equity
  #   Expense     | Debit             | Assets or services consumed in the generation of revenue
  #
  # Each account can also be marked as a "Contra Account". A contra account will have it's
  # normal balance swapped. For example, to remove equity, a "Drawing" account may be created
  # as a contra equity account as follows:
  #
  #   Plutus::Equity.create(:name => "Drawing", contra => true)
  #
  # At all times the balance of all accounts should conform to the "accounting equation"
  #   Plutus::Assets = Liabilties + Owner's Equity
  #
  # Each sublclass account acts as it's own ledger. See the individual subclasses for a
  # description.
  #
  # @abstract
  #   An account must be a subclass to be saved to the database. The Account class
  #   has a singleton method {trial_balance} to calculate the balance on all Accounts.
  #
  # @see http://en.wikipedia.org/wiki/Accounting_equation Accounting Equation
  # @see http://en.wikipedia.org/wiki/Debits_and_credits Debits, Credits, and Contra Accounts
  #
  # @author Michael Bulat
  class Account < ActiveRecord::Base
    attr_accessible :name, :contra
    attr_accessor  :start_date, :end_date

    has_many :credit_amounts, :include => :transaction, :conditions => proc { "plutus_transactions.date >= '#{start_date || "1900-01-01"}' AND plutus_transactions.date <= #{end_date || ( Date.today + 15.days ).to_s}" }
    has_many :debit_amounts,  :include => :transaction, :conditions => proc { "plutus_transactions.date >= '#{start_date || "1900-01-01"}' AND plutus_transactions.date <= #{end_date || ( Date.today + 15.days ).to_s}"    
    has_many :credit_transactions, :through => :credit_amounts, :source => :transaction
    has_many :debit_transactions, :through => :debit_amounts, :source => :transaction
    belongs_to :accountable, :polymorphic => true

    validates_presence_of :type, :name
    validates_uniqueness_of :name

    # The trial balance of all accounts in the system. This should always equal zero,
    # otherwise there is an error in the system.
    #
    # @example
    #   >> Account.trial_balance.to_i
    #   => 0
    #
    # @return [BigDecimal] The decimal value balance of all accounts
    def self.trial_balance
      unless self.new.class == Account
        raise(NoMethodError, "undefined method 'trial_balance'")
      else
        Asset.balance - (Liability.balance + Equity.balance + Revenue.balance - Expense.balance)
      end
    end

  end
end
