rm(list=ls()) ; gc()

library(tidyverse)
library(tidytext)
library(forcats)
library(lubridate)
library(aRxiv)
library(reshape2) #dcast function
library(wordcloud)



###################################

######1.Recover the figure on p.15 of Lectrue Slide 10.

data("data_corpus_inaugural", package = "quanteda")
inaug_dfm <- quanteda::dfm(data_corpus_inaugural,
                           verbose = FALSE)
inaug_td <- tidy(inaug_dfm)
inaug_tf_idf <- inaug_td %>%
  bind_tf_idf(term, document, count)
  

data <- inaug_tf_idf %>% 
  filter(document %in% c('1861-Lincoln','1933-Roosevelt','1961-Kennedy',
                         '2009-Obama')) %>%
  group_by(document) %>% 
  arrange(desc(document),desc(tf_idf)) %>% 
  top_n(10,tf_idf) %>%
  ungroup() %>% 
  mutate(term = reorder_within(term, tf_idf,document))



data %>% 
  ggplot(aes(term , tf_idf , fill=document)) + 
  facet_wrap( ~ document, scales = 'free') +
  geom_bar(stat='identity',show.legend = FALSE) +
  scale_x_reordered() +
  
  labs(x="") +
  labs(caption = "Made by Lee Dong Gyu" ) +
  
  theme(
    strip.text.x = element_text(color = "white",face = "bold"),
    strip.text.y = element_text(color = "white",face = "bold"),
    strip.background = element_rect(color="gray70",fill="gray70", 
                                    size=1.5, linetype="solid") , 
    axis.title.x = element_text(face='bold'),
    panel.background = element_blank() , 
    panel.grid.major.x = element_line(color='gray90') , 
    panel.grid.minor.x = element_line(color='gray90') ,
    panel.grid.major.y = element_line(color='gray90') , 
    panel.grid.minor.y = element_line(color='gray90') ) +
  coord_flip()


#####################################

#2. Analyze the SVM papers downloaded from aRxiv


# NNPaper <- arxiv_search(query = '"Neural Network"', limit = 1000)
# NNPaper <- as_tibble(SVMPaper)
# 
# NNPaper <- NNPaper %>%
#   mutate(submitted = ymd_hms(submitted), updated = ymd_hms(updated))
# write.csv(NNPaper,file='hello.csv') # write csv.
# glimpse(NNPaper)


tt <- read.csv('C:\\Users\\82104\\Desktop\\dat.csv') # data import
NNPaper<- tt[,-1] 
NNPaper <- as_tibble(NNPaper)
NNPaper <- NNPaper %>%
  mutate(submitted = ymd_hms(submitted), updated = ymd_hms(updated))




####2-1.plot Wordcloud except the term Neural Network
NNPaper$abstract <- as.character(NNPaper$abstract)
data1 <- NNPaper %>% 
  select(abstract) %>% 
  unnest_tokens(word,abstract)


data1 %>% 
  anti_join(stop_words) %>% 
  filter(!str_detect(word,'[\\d]')) %>%  #eliminating digit
  count(word) %>% 
  with(wordcloud(word,n,max.words=50), random.order=FALSE)



####2-2.Which year is generating these papers most freqently?
data2 <- NNPaper %>% 
  select(submitted,authors,title) %>% 
  extract(submitted,"year","(\\d+)",convert=TRUE) %>% 
  group_by(year) %>% 
  summarize(n=n()) %>% 
  mutate(year=factor(year))

data2 %>% 
  ggplot(aes(year , n , fill=year)) + 
  geom_bar(stat='identity',show.legend = FALSE) +
  
  labs(x="",y="") +
  geom_text(aes(label=n), position = position_dodge(width=0.7),fontface = "bold") +
  
  ggtitle("Paper Distribution by Year") +
  labs(caption = "Made by Lee Dong Gyu" ) +
  
  theme_bw()+
  theme(
    plot.title = element_text(face='bold',size=20),
    strip.text.x = element_text(color = "white",face = "bold"),
    strip.text.y = element_text(color = "white",face = "bold"),
    strip.background = element_rect(color="gray70",fill="gray70", 
                                    size=1.5, linetype="solid") , 
    axis.title.x = element_text(face='bold'),
    axis.text.y=element_text(face='bold'),
    axis.text.x=element_text(face='bold')) +
  coord_flip()


####2-3.What fields are generating these papers most frequently? (Check primary_category)

data3 <- NNPaper %>% 
  select(primary_category) %>% 
  group_by(primary_category) %>% 
  summarize(n=n()) %>% 
  mutate(primary_category=reorder(primary_category,n))

data3 %>% 
  ggplot(aes(primary_category , n , fill=primary_category)) + 
  geom_bar(stat='identity',show.legend = FALSE) +
  
  labs(x="",y="") +
  geom_text(aes(label=n), position = position_dodge(width=0.7),fontface = "bold") +
  
  ggtitle("Paper Distribution by fields") +
  labs(caption = "Made by Lee Dong Gyu" ) +
  
  theme(
    plot.title = element_text(face='bold',size=20),
    strip.text.x = element_text(color = "white",face = "bold"),
    strip.text.y = element_text(color = "white",face = "bold"),
    strip.background = element_rect(color="gray70",fill="gray70", 
                                    size=1.5, linetype="solid") , 
    axis.title.x = element_text(face='bold'),
    axis.text.y=element_text(face='bold.italic'),
    axis.text.x=element_text(face='bold.italic')) +
  coord_flip()


####2-4.Caculate tf-idf matrix. Here, the document is “article”.


data4 <- NNPaper %>% 
  select(title,abstract) %>% 
  mutate(abstract=as.character(abstract)) %>% 
  unnest_tokens(word,abstract) %>% 
  count(title,word,sort=TRUE) %>% 
  bind_tf_idf(word,title,n)

tf_idf_matrix <- data4 %>% 
  select(title, word, tf_idf) %>%
  dcast(word ~ title) %>% 
  as_tibble()

tf_idf_matrix[,1:5] 
dim(tf_idf_matrix)

####2-5.Conduct cluster analysis for the articles based on the tf_idf matrix.

#kmeans 

tf_idf_matrix[is.na(tf_idf_matrix)] <- 0
row_name <- tf_idf_matrix[,1] # terms
data5 <- as.matrix(tf_idf_matrix[,2:1000])
col_name <- colnames(data5) # document names
data5 <- t(data5)


# divided into 3 groups
kmeans2_5_group3 <- kmeans(data5,3) 
cluster <- as_tibble(kmeans2_5_group3$cluster) %>% 
  mutate(document=col_name)

for (i in  1)
cluster_1 <- length(cluster$value[cluster$value == 1])
cluster_2 <- length(cluster$value[cluster$value == 2])
cluster_3 <- length(cluster$value[cluster$value == 3])
c(cluster1=cluster_1 , cluster2=cluster_2,cluster3=cluster_3)


# divided into 4 groups
kmeans2_5_group4 <- kmeans(data5,4) 
cluster <- as_tibble(kmeans2_5_group4$cluster) %>% 
  mutate(document=col_name)

cluster_1 <- length(cluster$value[cluster$value == 1])
cluster_2 <- length(cluster$value[cluster$value == 2])
cluster_3 <- length(cluster$value[cluster$value == 3])
cluster_4 <- length(cluster$value[cluster$value == 4])
c(cluster1=cluster_1 , cluster2=cluster_2,cluster3=cluster_3,cluster4=cluster_4)
