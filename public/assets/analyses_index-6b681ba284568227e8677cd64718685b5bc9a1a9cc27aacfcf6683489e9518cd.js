const getCurrentTabStr=()=>`${document.querySelector("ul.nav-tabs>li.active").id.replace("-tab","")}`,periodSelect=document.querySelector("#period-select");periodSelect.addEventListener("change",e=>{document.querySelector("#expenses-search-btn").href=`${location.origin+location.pathname}?period=${e.target.value}&tab=${getCurrentTabStr()}`});const getChangeableLinkBtns=function(){return[document.querySelector("#last-month-btn"),document.querySelector("#next-month-btn"),document.querySelector("#expenses-search-btn")]},setSpecifyTab=()=>{const e=event.target.id.replace("-tab-link","");getChangeableLinkBtns().forEach(t=>{let n=`${t.href.replace(/tab=[a-z]+/,`tab=${e}`)}`;t.href=n})};document.querySelector("#expenses-tab-link").addEventListener("click",setSpecifyTab,!1),document.querySelector("#budgets-tab-link").addEventListener("click",setSpecifyTab,!1);const expensePanelHeading=document.querySelector("#expense-panel-heading"),icon=document.querySelector(".fa-caret-right");expensePanelHeading.addEventListener("click",()=>{icon&&icon.classList.toggle("rotate-arrow")}),window.onload=function(){if("expenses"===arg.tab&&arg.category){const e=arg.category,t=document.querySelector(`#expenses-comparison-category-id-${e}`).getBoundingClientRect();window.scrollBy({top:t.top-30,behavior:"smooth"})}};