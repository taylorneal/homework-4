library(tidyverse)
library(LICORS)
library(foreach)
library(arules)
library(arulesViz)
library(igraph)
library(corrplot)
library(knitr)

wine <- read.csv("https://raw.githubusercontent.com/taylorneal/homework-4/master/data/wine.csv", header = TRUE)
social_marketing <- read.csv("https://raw.githubusercontent.com/taylorneal/homework-4/master/data/social_marketing.csv", header = TRUE)
groceries <- readLines("https://raw.githubusercontent.com/taylorneal/homework-4/master/data/groceries.txt")

set.seed(12)

X = wine[,(1:11)]
X = scale(X, center = TRUE, scale = TRUE)

clust1 = kmeanspp(X, k = 3, nstart = 10)

ggplot(wine) + 
  geom_point(aes(alcohol, total.sulfur.dioxide, 
                 fill = factor(clust1$cluster), color = color), size = 2, pch = 21) + 
  scale_fill_manual(values=c("blue", "cyan", "red")) #+ facet_wrap(~quality)

wine$predict_rw = 'Correct'
wine[clust1$cluster == 3 & wine$color == 'white', 'predict_rw'] = 
  'Incorrect (white)'
wine[clust1$cluster != 3 & wine$color == 'red', 'predict_rw'] = 
  'Incorrect (red)'
white_pct = 1 - sum(wine$predict_rw == 'Incorrect (white)') / 
  sum(wine$color == 'white')
red_pct = 1 - sum(wine$predict_rw == 'Incorrect (red)') / 
  sum(wine$color == 'red')

ggplot(wine) + 
  geom_point(aes(alcohol, total.sulfur.dioxide, 
                 color = factor(predict_rw)), size = 2) +
  scale_color_manual(values=c("light gray", "red", "cyan"))

#qplot(volatile.acidity, total.sulfur.dioxide, data = wine, color = factor(clust1$cluster), shape = color)
#qplot(Horsepower, CityMPG, data=cars, color=factor(clust1$cluster))

k_grid = seq(2, 8, by = 1)
N = nrow(X)
CH_grid = foreach(k = k_grid, .combine = 'c') %do% {
  cluster_k = kmeanspp(X, k, nstart = 10)
  W = cluster_k$tot.withinss
  B = cluster_k$betweenss
  CH = (B/W)*((N-k)/(k-1))
  CH
}


### PCA

PCA = prcomp(X, rank = 11)

plot(PCA)
head(PCA$rotation)
summary(PCA)

kable(round(PCA$rotation[,1:5],2))

PCA$rotation
PCA$x[,1]

ggplot(wine) + 
  geom_point(aes(alcohol, total.sulfur.dioxide, 
                 color = PCA$x[,1]), size = 2) +
  scale_color_gradient2(low = 'red', mid = 'light grey', high = 'cyan', 
                        name = 'PC1') #+ facet_wrap(~quality)


##########
##########
##########

SM = social_marketing[,c(3:5,7:37)]
#X = scale(X, center = TRUE, scale = TRUE)

PCA = prcomp(SM, rank = 10)

summary(PCA)
round(PCA$rotation[,1:5],2)

cor_SM = cor(SM)
#which(cor_X > 0.5)
cor_SM[cor_SM > 0.5]

k_grid = seq(2, 15, by = 1)
N = nrow(SM)
CH_grid = foreach(k = k_grid, .combine = 'c') %do% {
  cluster_k = kmeanspp(SM, k, nstart = 20)
  W = cluster_k$tot.withinss
  B = cluster_k$betweenss
  CH = (B/W)*((N-k)/(k-1))
  CH
}

cluster1 = kmeanspp(SM, 6, nstart = 10)


zdf <- as.data.frame(as.table(cor_X))
count(subset(zdf, abs(Freq) > 0.3 & abs(Freq) != 1))

subset(zdf, abs(Freq) > 0.3 & abs(Freq) != 1)

corrplot(cor_SM, type="upper", order="hclust")

heatmap(as.matrix(SM[cluster1$cluster == 1,]), Colv = NA, Rowv = NA)
heatmap(as.matrix(SM[cluster1$cluster == 2,]), Colv = NA, Rowv = NA)
heatmap(as.matrix(SM[cluster1$cluster == 3,]), Colv = NA, Rowv = NA)
heatmap(as.matrix(SM[cluster1$cluster == 4,]), Colv = NA, Rowv = NA)
heatmap(as.matrix(SM[cluster1$cluster == 5,]), Colv = NA, Rowv = NA)
heatmap(as.matrix(SM[cluster1$cluster == 6,]), Colv = NA, Rowv = NA)

## college_uni, sports_playing, online_gaming (4)
## cooking, beauty, fashion, shopping, photo_sharing (6)
## travel, politics, computers, news, automotive (10)
## health_nutrition, personal_fitness, outdoors (6)
## religion, school, parenting, sports_fandom, food, family (11)

# tv_film, art (2)

##########
##########
##########

groceries = split(groceries, seq_len(length(groceries)))
#scan(text = groceries[[1]], what = '', sep = ',')

for (i in seq(length(groceries))) {
  groceries[[i]] = scan(text = groceries[[i]], what = '', sep = ',', 
                        quiet = TRUE)
}
rm(i)

groceries = lapply(groceries, unique)

groceries = as(groceries, "transactions")

rules = apriori(groceries, 
                parameter=list(support=.01, confidence=.1, maxlen=2))

inspect(rules)

sub1 = subset(rules, lift > 1.8 & confidence > 0.3)

inspect(sub1)

plot(rules)
plot(subset(rules, lift > 1.0001), measure = c("support", "lift"), shading = "confidence")
plot(rules, method = 'two-key plot')

summary(sub1)
#plot(sub1, measure = c("support", "lift"), shading = "confidence")
plot(sub1, method = 'graph')
