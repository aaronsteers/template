# Products

```sql products
select 
    product, 
    '/products/' || product as link
from orders
group by product
```

<DataTable data={products} link=link/>

