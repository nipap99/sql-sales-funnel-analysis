# Sales Funnel Analysis in SQL
SQL-based sales funnel analysis exploring user conversion rates,  traffic source performance, and revenue metrics using PostgreSQL.
## Project Overview
Analysis of a user events dataset to understand 
conversion rates through a sales funnel.

## Queries Included
- Funnel stage conversion rates
- Traffic source breakdown
- User journey time analysis
- Revenue analysis

## Tools Used
- PostgreSQL
- pgAdmin

---

## Final Recommendations

### 1. UX & Website Optimization
**Don't Touch the Checkout Flow:** The conversion rates from Checkout Start to Purchase
are excellent (~80%+). This indicates the technical payment flow is frictionless.
- *Action:* Do not redesign the checkout page right now; you risk breaking something 
that is working perfectly.

### 2. Marketing Strategy
**Stop Over-Investing in Social for Sales:** Social Media is driving 30% of our traffic 
(Volume) but has the lowest conversion rate (Efficiency). We are likely paying for "window shoppers."
- *Action:* Shift budget away from "Traffic" objectives on social ads and focus on 
"Retargeting" or "Lead Gen" to capture emails instead.

**Double Down on Email Marketing:** Email is our highest converting channel 
(~13%+ conversion rate vs ~6% for Social).
- *Action:* Implement an aggressive email capture popup for those high-volume Social 
visitors. If we can get them onto our email list, our data proves they are far more 
likely to buy later.

### 3. Financial & Revenue
**Audit Ad Spend against AOV:** We found our Average Order Value is ~$115.
- *Action:* Set a strict Customer Acquisition Cost (CAC) limit. If we are paying more 
than $30-$40 to acquire a customer via Social Media ads (which convert poorly), 
we are likely losing money on those specific transactions.
