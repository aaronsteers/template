# Products

```sql products
select 
    product, 
    '/products/' || product as link
from orders
group by product
```

<DataTable data={products} link=link/>

{#each products as product}

[{product.product}](/products/{product.product})

{/each}