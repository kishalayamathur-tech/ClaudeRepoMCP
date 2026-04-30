/**
 * @description Controller for the myAccounts LWC component.
 *              Returns a paginated set of Account records and the total count.
 */
public with sharing class AccountController {

    /**
     * @description Retrieves a page of Account records and the total qualifying count.
     * @param pageSize Number of accounts to return per page.
     * @param pageOffset Zero-based record offset for the current page.
     * @return AccountResult wrapper containing the accounts list and totalCount.
     */
    @AuraEnabled(cacheable=true)
    public static AccountResult getAccounts(Integer pageSize, Integer pageOffset) {
        Integer safePageSize   = (pageSize   != null && pageSize   >= 1) ? pageSize   : 10;
        Integer safePageOffset = (pageOffset != null && pageOffset >= 0) ? pageOffset : 0;

        List<Account> accountList = [
            SELECT Id, Name, Industry, Phone, AnnualRevenue, Rating
            FROM Account
            WHERE RecordType.Name = 'Business'
              AND Rating != null
              AND AnnualRevenue != null
              AND Phone != null
            WITH USER_MODE
            ORDER BY Name ASC
            LIMIT :safePageSize
            OFFSET :safePageOffset
        ];

        Integer totalCount = [
            SELECT COUNT()
            FROM Account
            WHERE RecordType.Name = 'Business'
              AND Rating != null
              AND AnnualRevenue != null
              AND Phone != null
            WITH USER_MODE
        ];

        List<AccountWrapper> wrappers = new List<AccountWrapper>();
        for (Account acc : accountList) {
            AccountWrapper wrapper = new AccountWrapper();
            wrapper.accountId     = acc.Id;
            wrapper.name          = acc.Name;
            wrapper.industry      = acc.Industry;
            wrapper.phone         = acc.Phone;
            wrapper.annualRevenue = acc.AnnualRevenue;
            wrapper.rating        = acc.Rating;
            wrappers.add(wrapper);
        }

        AccountResult result = new AccountResult();
        result.accounts      = wrappers;
        result.totalCount    = totalCount;
        return result;
    }

    public class AccountWrapper {
        @AuraEnabled public String  accountId;
        @AuraEnabled public String  name;
        @AuraEnabled public String  industry;
        @AuraEnabled public String  phone;
        @AuraEnabled public Decimal annualRevenue;
        @AuraEnabled public String  rating;
    }

    public class AccountResult {
        @AuraEnabled public List<AccountWrapper> accounts;
        @AuraEnabled public Integer              totalCount;
    }
}