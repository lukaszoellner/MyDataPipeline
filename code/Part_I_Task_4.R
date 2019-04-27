library(ggplot2)
library(data.table)
library(tidyverse)
library(here())
library(stringr)
library(ggthemes)
library(reshape)  
library(knitr)


dataf<- fread("./data/df_Task_4.csv")
dataf 

colnames(dataf) <- colnames(dataf) %>% str_to_lower()
tdataf<-transform(dataf, retired= round(retired/10,0))
data.4 = melt(tdataf, id.vars = "year", variable.name = "Industries", value.name = "Contributions")


p<- ggplot(data.4, aes(year, Contributions/1000, group= Industries, colour= Industries))
p<- p+theme(plot.margin = margin(1,1,1,1,"cm"),
            plot.title = element_text(hjust = 0.5),
            axis.title.y.right = element_text(color = "#333366"),
            panel.grid.minor = element_blank(), 
            panel.grid.major = element_line(color = "gray60", size = 0.5),
            panel.grid.major.x = element_blank(),
            panel.background = element_blank(),
            axis.text.y.right = element_text(color =  "#333366"))
p<- p+ geom_line(size=1.5)
p<- p+ scale_color_manual(values=c('grey1','gray30','gray50','gray80','#333366'))
p<- p + scale_y_continuous(breaks = seq(0,40,5), sec.axis = sec_axis(~.*10, name=" (retired) Campaign Contributions [in 1000]"), expand=c(0,0))
p<- p+ coord_cartesian(xlim=c(1990, 2012), ylim = c(0,42))
p<- p+ ylab("Campaign Contributions [in 1000]")+xlab("Year") + ggtitle("Number of Campaign Contributions by Individuals")
p
